// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {SimpleBase} from "src/improvements/tasks/types/SimpleBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

import {
    IDeputyGuardianModule,
    ISuperchainConfig
} from "lib/optimism/packages/contracts-bedrock/interfaces/safe/IDeputyGuardianModule.sol";

/// @title UnpauseTemplate
/// @notice This template is used to unpause the SuperchainConfig contract.
contract UnpauseTemplate is SimpleBase {
    using stdToml for string;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "FoundationOperationsSafe";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](3);
        storageWrites[0] = "DeputyGuardianModule";
        storageWrites[1] = "Guardian";
        storageWrites[2] = "SuperchainConfig";
        return storageWrites;
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        // Load the DeputyGuardianModule contract.
        IDeputyGuardianModule dgm = IDeputyGuardianModule(simpleAddrRegistry.get("DeputyGuardianModule"));

        // Unpause the SuperchainConfig contract.
        dgm.unpause();
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        // Load the SuperchainConfig contract.
        ISuperchainConfig sc = ISuperchainConfig(simpleAddrRegistry.get("SuperchainConfig"));

        // Validate that the SuperchainConfig contract is unpaused.
        assertEq(sc.paused(), false);
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory codeExceptions = new address[](0);
        return codeExceptions;
    }
}
