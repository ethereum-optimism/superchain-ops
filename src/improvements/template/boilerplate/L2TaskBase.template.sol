// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// TODO: If you need any interfaces from the Optimism monorepo submodule. Define them here instead of importing them.
/// Doing this avoids tight coupling to the monorepo submodule and allows you to update the monorepo submodule
/// without having to update the template (Remove this comment when done).

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

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        require(false, "TODO: Implement with the correct storage writes.");
        return new string[](0);
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {
        require(false, "TODO: Implement with the correct balance changes.");
        return new string[](0);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();
        _chains;

        require(false, "TODO: Implement with the correct template setup.");
    }

    /// @notice Before implementing the `_build` function, task developers must consider the following:
    /// 1. Which Multicall contract does this template use — `Multicall3` or `Multicall3Delegatecall`?
    /// 2. Based on the contract, should the target be called using `call` or `delegatecall`?
    /// 3. Ensure that the call to the target uses the appropriate method (`call` or `delegatecall`) accordingly.
    /// Guidelines:
    /// - `Multicall3`:
    ///  If the template directly inherits from `L2TaskBase` or `SimpleTaskBase`, it uses the `Multicall3` contract.
    ///  In this case, calls to the target **must** use `call`, e.g.:
    ///  ` dgm.setRespectedGameType(IOptimismPortal2(payable(portalAddress)), cfg[chainId].gameType);`
    /// WARNING: Any state written to in this function will be reverted after the build function has been run.
    /// Do not rely on setting global variables in this function.
    function _build() internal override {
        // Do not set global variables in this function, see natspec above.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(false, "TODO: Implement with the correct build logic.");
            cfg[chainId] = ExampleTaskConfig({chainId: chainId}); // No-op (does nothing)
            chainId; // No-op (does nothing)
        }
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
