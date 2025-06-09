// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface ISystemConfig {
    function setGasLimit(uint64 _gasLimit) external;
    function setEIP1559Params(uint32 _denominator, uint32 _elasticity) external;
    function gasLimit() external view returns (uint64);
    function eip1559Denominator() external view returns (uint32);
    function eip1559Elasticity() external view returns (uint32);
}

/// @notice A template contract for configuring L2TaskBase templates.
/// Supports: anything after Holocene
contract SystemConfigGasParams is L2TaskBase {
    /// @notice Optional: struct representing configuration for the task.
    struct TaskInputs {
        uint64 gasLimit;
        uint32 eip1559Denominator;
        uint32 eip1559Elasticity;
    }

    /// @notice Optional: mapping of chain ID to configuration for the task.
    mapping(uint256 => TaskInputs) public cfg;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "FoundationUpgradeSafe";
    }

    /// @notice Returns the storage write permissions required for this task
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "SystemConfigProxy";
        storageWrites[1] = "FoundationUpgradeSafe";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);

        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();

        // Read gas parameters from the cached TOML content
        uint64 gasLimit = uint64(vm.parseTomlUint(tomlContent, ".gasParams.gasLimit"));
        uint32 eip1559Elasticity = uint32(vm.parseTomlUint(tomlContent, ".gasParams.eip1559Elasticity"));
        uint32 eip1559Denominator = uint32(vm.parseTomlUint(tomlContent, ".gasParams.eip1559Denominator"));

        // Set the configuration for each chain
        for (uint256 i = 0; i < _chains.length; i++) {
            uint256 chainId = _chains[i].chainId;
            cfg[chainId] = TaskInputs({
                gasLimit: gasLimit,
                eip1559Denominator: eip1559Denominator,
                eip1559Elasticity: eip1559Elasticity
            });
        }
    }

    /// @notice Update the gas limit and EIP1559 parameters for the SystemConfig contract.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            TaskInputs memory taskInput = cfg[chainId];
            address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
            ISystemConfig(systemConfigProxy).setGasLimit(taskInput.gasLimit);
            ISystemConfig(systemConfigProxy).setEIP1559Params(taskInput.eip1559Denominator, taskInput.eip1559Elasticity);
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
            TaskInputs memory taskInput = cfg[chainId];
            require(ISystemConfig(systemConfigProxy).gasLimit() == taskInput.gasLimit, "Gas limit mismatch");
            require(
                ISystemConfig(systemConfigProxy).eip1559Denominator() == taskInput.eip1559Denominator,
                "EIP1559 denominator mismatch"
            );
            require(
                ISystemConfig(systemConfigProxy).eip1559Elasticity() == taskInput.eip1559Elasticity,
                "EIP1559 elasticity mismatch"
            );
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}
