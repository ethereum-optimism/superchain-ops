// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

/// @notice A template contract for configuring L2TaskBase templates.
/// Supports: <TODO: add supported tags: e.g. op-contracts/v*.*.*>
contract L2TaskBaseTemplate is L2TaskBase {
    /// @notice Optional: struct representing configuration for the task.
    struct ExampleTaskConfig {
        uint256 chainId;
    }

    /// @notice Optional: mapping of chain ID to configuration for the task.
    mapping(uint256 => ExampleTaskConfig) public cfg;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        require(false, "TODO: Implement with the correct safe address string.");
        return "";
    }

    /// @notice Returns the storage write permissions required for this task
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        require(false, "TODO: Implement with the correct storage writes.");
        return new string[](0);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory _chains = abi.decode(
            vm.parseToml(vm.readFile(taskConfigFilePath), ".l2chains"), (SuperchainAddressRegistry.ChainInfo[])
        );
        _chains;

        require(false, "TODO: Implement with the correct template setup.");
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(false, "TODO: Implement with the correct build logic.");
            cfg[chainId] = ExampleTaskConfig({chainId: chainId}); // No-op (does nothing)
            chainId; // No-op (does nothing)
        }
    }

    /// @notice Template developers must override this function and make a call to 'StandardValidator.validate()'.
    function _standardValidatorCheck() internal pure override {
        require(false, "TODO: Call StandardValidator.validate()");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            require(false, "TODO: Implement with the correct validation logic.");
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        require(
            false, "TODO: Implement the logic to return a list of addresses that should not be checked for code length."
        );
        address[] memory codeExceptions = new address[](1);
        codeExceptions[0] = address(0);
        return codeExceptions;
    }
}

/// TODO: If you need any interfaces from the Optimism monorepo submodule. Define them here instead of importing them.
/// Doing this avoids tight coupling to the monorepo submodule and allows you to update the monorepo submodule
/// without having to update the template.
