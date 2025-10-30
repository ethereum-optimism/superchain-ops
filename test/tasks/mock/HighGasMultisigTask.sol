// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MockTarget} from "test/tasks/mock/MockTarget.sol";

/// @notice Mock task that consumes a lot of gas to test that MultisigTask correctly rejects
///         transactions that consume gas too close to the Fusaka EIP-7825 cap of 16,777,216 gas.
contract HighGasMultisigTask is L2TaskBase {
    /// @notice reference to the mock target contract
    MockTarget public mockTarget;

    /// @notice Returns the safe address string identifier
    /// @return The string "ProxyAdminOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "ProxyAdminOwner";
        return storageWrites;
    }

    function _templateSetup(string memory, address rootSafe) internal override {
        super._templateSetup("", rootSafe);
        // Initialize mockTarget so it's available when _build() runs
        mockTarget = new MockTarget();
    }

    /// @notice Build function that creates an action which will consume >14M gas on-chain
    function _build(address) internal override {
        // Call mockTarget.consumeGas() which will expand memory during execution to use a lot of gas
        mockTarget.consumeGas();
    }

    /// @notice Validates that the task executed
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {}

    /// @notice No code exceptions for this template.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
