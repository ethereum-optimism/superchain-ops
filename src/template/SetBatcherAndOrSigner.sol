// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface ISystemConfig {
    function setBatcherHash(bytes32 _batcherHash) external;
    function setUnsafeBlockSigner(address _unsafeBlockSigner) external;
    function batcherHash() external view returns (bytes32);
    function unsafeBlockSigner() external view returns (address);
    function owner() external view returns (address);
}

/// @notice Template for updating the batcher hash and unsafe block signer on SystemConfig.
/// Requested calls are batched into a single Multicall3 transaction from the SystemConfig owner.
contract SetBatcherAndOrSigner is L2TaskBase {
    using stdToml for string;

    /// @notice Configuration for each chain's batcher and signer update.
    struct TaskInputs {
        bytes32 batcherHash;
        address unsafeBlockSigner;
        bool updateBatcher;
        bool updateUnsafeBlockSigner;
    }

    /// @notice Mapping of chain ID to configuration for the task.
    mapping(uint256 => TaskInputs) public cfg;

    /// @notice Returns the safe address string identifier.
    /// Must be set via `safeAddressString` in the task's config.toml.
    function safeAddressString() public pure override returns (string memory) {
        revert("SetBatcherAndOrSigner: safeAddressString must be set in the config file");
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "SystemConfigProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with configuration from a TOML file.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);

        string memory tomlContent = vm.readFile(_taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();

        address requestedBatcher = tomlContent.readAddress(".sequencerConfig.batcherAddress");
        address requestedUnsafeBlockSigner = tomlContent.readAddress(".sequencerConfig.unsafeBlockSigner");
        bool hasUpdateBatcher = tomlContent.keyExists(".sequencerConfig.updateBatcher");
        bool hasUpdateUnsafeBlockSigner = tomlContent.keyExists(".sequencerConfig.updateUnsafeBlockSigner");
        require(
            hasUpdateBatcher == hasUpdateUnsafeBlockSigner, "SetBatcherAndOrSigner: both update flags must be provided"
        );
        bool configuredUpdateBatcher = hasUpdateBatcher && tomlContent.readBool(".sequencerConfig.updateBatcher");
        bool configuredUpdateUnsafeBlockSigner =
            hasUpdateUnsafeBlockSigner && tomlContent.readBool(".sequencerConfig.updateUnsafeBlockSigner");
        if (hasUpdateBatcher) {
            _requireRequestedUpdate(configuredUpdateBatcher, configuredUpdateUnsafeBlockSigner);
        }

        for (uint256 i = 0; i < _chains.length; i++) {
            uint256 chainId = _chains[i].chainId;
            ISystemConfig systemConfig = ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId));
            _requireRootSafe(_rootSafe, systemConfig.owner());

            address currentBatcher = _decodeBatcherAddress(systemConfig.batcherHash());
            address currentUnsafeBlockSigner = systemConfig.unsafeBlockSigner();
            address batcherAddress =
                _resolveTarget(requestedBatcher, hasUpdateBatcher ? configuredUpdateBatcher : true, currentBatcher);
            address unsafeBlockSigner = _resolveTarget(
                requestedUnsafeBlockSigner,
                hasUpdateUnsafeBlockSigner ? configuredUpdateUnsafeBlockSigner : true,
                currentUnsafeBlockSigner
            );
            bool updateBatcher = hasUpdateBatcher ? configuredUpdateBatcher : batcherAddress != currentBatcher;
            bool updateUnsafeBlockSigner = hasUpdateUnsafeBlockSigner
                ? configuredUpdateUnsafeBlockSigner
                : unsafeBlockSigner != currentUnsafeBlockSigner;
            bytes32 batcherHash = bytes32(uint256(uint160(batcherAddress)));
            require(
                (updateBatcher && batcherAddress != currentBatcher)
                    || (updateUnsafeBlockSigner && unsafeBlockSigner != currentUnsafeBlockSigner),
                "SetBatcherAndOrSigner: no-op (requested fields already match current values)"
            );
            cfg[chainId] = TaskInputs({
                batcherHash: batcherHash,
                unsafeBlockSigner: unsafeBlockSigner,
                updateBatcher: updateBatcher,
                updateUnsafeBlockSigner: updateUnsafeBlockSigner
            });
        }
    }

    /// @notice Builds the batched transaction, calling only the requested setters.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            TaskInputs memory taskInput = cfg[chainId];
            address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
            if (taskInput.updateBatcher) {
                ISystemConfig(systemConfigProxy).setBatcherHash(taskInput.batcherHash);
            }
            if (taskInput.updateUnsafeBlockSigner) {
                ISystemConfig(systemConfigProxy).setUnsafeBlockSigner(taskInput.unsafeBlockSigner);
            }
        }
    }

    /// @notice Validates that the batcher hash and unsafe block signer were updated correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
            TaskInputs memory taskInput = cfg[chainId];
            require(
                ISystemConfig(systemConfigProxy).batcherHash() == taskInput.batcherHash,
                "SetBatcherAndOrSigner: batcher hash mismatch"
            );
            require(
                ISystemConfig(systemConfigProxy).unsafeBlockSigner() == taskInput.unsafeBlockSigner,
                "SetBatcherAndOrSigner: unsafe block signer mismatch"
            );
        }
    }

    /// @notice Whitelists for each chain's Batcher and UnsafeBlockSigner since batcher and signer addresses are EOAs.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address[] memory exceptions = new address[](chains.length * 2);
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            TaskInputs memory taskInput = cfg[chainId];
            exceptions[i * 2] = address(uint160(uint256(taskInput.batcherHash)));
            exceptions[i * 2 + 1] = taskInput.unsafeBlockSigner;
        }
        return exceptions;
    }

    function _resolveTarget(address requested, bool updateRequested, address current) internal pure returns (address) {
        if (!updateRequested) return current;
        require(requested != address(0), "SetBatcherAndOrSigner: requested target is zero address");
        return requested;
    }

    function _requireRequestedUpdate(bool updateBatcher, bool updateUnsafeBlockSigner) internal pure {
        require(updateBatcher || updateUnsafeBlockSigner, "SetBatcherAndOrSigner: no update requested");
    }

    function _requireRootSafe(address rootSafe, address owner) internal pure {
        require(rootSafe == owner, "SetBatcherAndOrSigner: root safe is not SystemConfig owner");
    }

    function _decodeBatcherAddress(bytes32 batcherHash) internal pure returns (address) {
        require(uint256(batcherHash) >> 160 == 0, "SetBatcherAndOrSigner: batcher hash is not an address");
        address batcher = address(uint160(uint256(batcherHash)));
        require(batcher != address(0), "SetBatcherAndOrSigner: current batcher is zero address");
        return batcher;
    }
}
