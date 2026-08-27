// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface ISystemConfig {
    function setGasLimit(uint64 _gasLimit) external;
    function gasLimit() external view returns (uint64);
}

/// @notice A template that sets ONLY the SystemConfig gas limit (no EIP-1559 params).
/// This is the minimal action for the Karst (U19) gas-limit reset: re-issuing
/// `setGasLimit` re-emits the gas `ConfigUpdate`, which is all that is required to clear
/// the post-activation +55 MGas. The gas limit is set by the SystemConfig owner, so the
/// task is rooted at "SystemConfigOwner" by default (override via `safeAddressString` in
/// config.toml if needed).
/// Supports: anything after Holocene.
contract SystemConfigGasLimit is L2TaskBase {
    /// @notice Struct representing configuration for the task.
    struct TaskInputs {
        uint64 gasLimit;
    }

    /// @notice Mapping of chain ID to configuration for the task.
    mapping(uint256 => TaskInputs) public cfg;

    /// @notice Returns the safe address string identifier. The gas limit is owned by the
    /// SystemConfig owner; resolved per-chain via `SystemConfig.owner()`.
    function safeAddressString() public pure override returns (string memory) {
        return "SystemConfigOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "SystemConfigProxy";
        storageWrites[1] = "SystemConfigOwner";
        return storageWrites;
    }

    /// @notice Sets up the template with the gas limit from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);

        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();

        // Read the gas limit from the cached TOML content.
        uint64 gasLimit = uint64(vm.parseTomlUint(tomlContent, ".gasParams.gasLimit"));

        // Set the configuration for each chain.
        for (uint256 i = 0; i < _chains.length; i++) {
            cfg[_chains[i].chainId] = TaskInputs({gasLimit: gasLimit});
        }
    }

    /// @notice Update the gas limit for the SystemConfig contract.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
            ISystemConfig(systemConfigProxy).setGasLimit(cfg[chainId].gasLimit);
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
            require(ISystemConfig(systemConfigProxy).gasLimit() == cfg[chainId].gasLimit, "Gas limit mismatch");
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
