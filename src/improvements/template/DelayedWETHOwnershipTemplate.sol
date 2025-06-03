// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

import {IDelayedWETH} from "lib/optimism/packages/contracts-bedrock/interfaces/dispute/IDelayedWETH.sol";

/// @title DelayedWETHOwnershipTemplate
contract DelayedWETHOwnershipTemplate is SimpleTaskBase {
    using stdToml for string;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "FoundationOperationsSafe";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "DelayedWETH";
        storageWrites[1] = "PermissionedDelayedWETH";
        return storageWrites;
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        // Load the DelayedWETH contract.
        IDelayedWETH delayedWeth = IDelayedWETH(payable(simpleAddrRegistry.get("DelayedWETH")));

        // Load the PermissionedDelayedWETH contract.
        IDelayedWETH permissionedDelayedWeth = IDelayedWETH(payable(simpleAddrRegistry.get("PermissionedDelayedWETH")));

        // Load the address of the ProxyAdmin owner.
        address proxyAdminOwner = simpleAddrRegistry.get("ProxyAdminOwner");

        // Transfer ownership of the DelayedWETH contract to the ProxyAdmin owner.
        delayedWeth.transferOwnership(proxyAdminOwner);

        // Transfer ownership of the PermissionedDelayedWETH contract to the ProxyAdmin owner.
        permissionedDelayedWeth.transferOwnership(proxyAdminOwner);
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        // Load the DelayedWETH contract.
        IDelayedWETH delayedWeth = IDelayedWETH(payable(simpleAddrRegistry.get("DelayedWETH")));

        // Load the PermissionedDelayedWETH contract.
        IDelayedWETH permissionedDelayedWeth = IDelayedWETH(payable(simpleAddrRegistry.get("PermissionedDelayedWETH")));

        // Load the address of the ProxyAdmin owner.
        address proxyAdminOwner = simpleAddrRegistry.get("ProxyAdminOwner");

        // Check that the DelayedWETH contract is owned by the ProxyAdmin owner.
        assertEq(delayedWeth.owner(), proxyAdminOwner);

        // Check that the PermissionedDelayedWETH contract is owned by the ProxyAdmin owner.
        assertEq(permissionedDelayedWeth.owner(), proxyAdminOwner);
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory codeExceptions = new address[](0);
        return codeExceptions;
    }
}
