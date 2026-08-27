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
/// Both calls are batched into a single Multicall3 transaction from the SystemConfig owner.
contract SetBatcherAndOrSigner is L2TaskBase {
    using stdToml for string;

    /// @notice Configuration for each chain's batcher and signer update.
    struct TaskInputs {
        bytes32 batcherHash;
        address unsafeBlockSigner;
        bool updateBatcher;
        bool updateSigner;
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

        _loadConfig(_taskConfigFilePath);
    }

    /// @notice Simulates the update when SystemConfig is directly owned by an EOA.
    function simulateOwner(string memory taskConfigFilePath) public {
        address owner = _setupOwnerExecution(taskConfigFilePath);
        vm.startPrank(owner);
        _setBatcherAndOrSigner();
        vm.stopPrank();
        _validateBatcherAndOrSigner();
    }

    /// @notice Checks that the selected signer is the direct SystemConfig owner.
    function validateOwner(string memory taskConfigFilePath, address signer) public {
        address owner = _setupOwnerExecution(taskConfigFilePath);
        require(signer == owner, "SetBatcherAndOrSigner: signer is not SystemConfig owner");
    }

    /// @notice Broadcasts the update directly from the SystemConfig owner.
    function executeOwner(string memory taskConfigFilePath, address signer) public {
        address owner = _setupOwnerExecution(taskConfigFilePath);
        require(signer == owner, "SetBatcherAndOrSigner: signer is not SystemConfig owner");

        vm.startBroadcast(signer);
        _setBatcherAndOrSigner();
        vm.stopBroadcast();
        _validateBatcherAndOrSigner();
    }

    function _setupOwnerExecution(string memory taskConfigFilePath) internal returns (address owner) {
        superchainAddrRegistry = new SuperchainAddressRegistry(taskConfigFilePath);
        _loadConfig(taskConfigFilePath);

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        owner = superchainAddrRegistry.getAddress("SystemConfigOwner", chains[0].chainId);
        require(owner.code.length == 0, "SetBatcherAndOrSigner: owner execution requires an EOA");
        for (uint256 i = 0; i < chains.length; i++) {
            address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId);
            require(
                ISystemConfig(systemConfigProxy).owner() == owner,
                "SetBatcherAndOrSigner: configured owner is not SystemConfig owner"
            );
            if (i == 0) continue;
            require(
                superchainAddrRegistry.getAddress("SystemConfigOwner", chains[i].chainId) == owner,
                "SetBatcherAndOrSigner: chains have different owners"
            );
        }
    }

    function _loadConfig(string memory taskConfigFilePath) internal {
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();

        address batcherAddress = tomlContent.readAddress(".sequencerConfig.batcherAddress");
        address unsafeBlockSigner = tomlContent.readAddress(".sequencerConfig.unsafeBlockSigner");
        require(batcherAddress != address(0), "SetBatcherAndOrSigner: batcherAddress is zero address");
        require(unsafeBlockSigner != address(0), "SetBatcherAndOrSigner: unsafeBlockSigner is zero address");
        bytes32 batcherHash = bytes32(uint256(uint160(batcherAddress)));

        for (uint256 i = 0; i < _chains.length; i++) {
            uint256 chainId = _chains[i].chainId;
            ISystemConfig systemConfig = ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId));
            bool updateBatcher = batcherHash != systemConfig.batcherHash();
            bool updateSigner = unsafeBlockSigner != systemConfig.unsafeBlockSigner();
            require(
                updateBatcher || updateSigner, "SetBatcherAndOrSigner: no-op (both fields already match current values)"
            );
            cfg[chainId] = TaskInputs({
                batcherHash: batcherHash,
                unsafeBlockSigner: unsafeBlockSigner,
                updateBatcher: updateBatcher,
                updateSigner: updateSigner
            });
        }
    }

    /// @notice Builds the batched transaction, calling only the setters for fields that actually change.
    function _build(address) internal override {
        _setBatcherAndOrSigner();
    }

    function _setBatcherAndOrSigner() internal {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            TaskInputs memory taskInput = cfg[chainId];
            address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
            if (taskInput.updateBatcher) {
                ISystemConfig(systemConfigProxy).setBatcherHash(taskInput.batcherHash);
            }
            if (taskInput.updateSigner) {
                ISystemConfig(systemConfigProxy).setUnsafeBlockSigner(taskInput.unsafeBlockSigner);
            }
        }
    }

    /// @notice Validates that the batcher hash and unsafe block signer were updated correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        _validateBatcherAndOrSigner();
    }

    function _validateBatcherAndOrSigner() internal view {
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
}
