// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {VerificationBase} from "script/verification/Verification.s.sol";
import {CommonBase} from "forge-std/Base.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

contract CouncilFoundationNestedSign is VerificationBase, CommonBase {
    GnosisSafe councilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    // The slot used to store the livenessGuard address in GnosisSafe.
    // See https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/base/GuardManager.sol#L30
    bytes32 constant livenessGuardSlot = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    constructor() {
        _addCodeExceptions();
        _addAllowedStorageAccesses();
    }

    function _addCodeExceptions() internal {
        address[] memory securityCouncilSafeOwners = councilSafe.getOwners();
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            address owner = securityCouncilSafeOwners[i];
            if (securityCouncilSafeOwners[i].code.length == 0) {
                addCodeException(owner);
            }
        }
    }

    function _addAllowedStorageAccesses() internal {
        addAllowedStorageAccess(address(councilSafe));
        addAllowedStorageAccess(address(fndSafe));
        addAllowedStorageAccess(address(ownerSafe));
        addAllowedStorageAccess(livenessGuard());
    }

    function livenessGuard() public view returns (address) {
        return address(uint160(uint256(vm.load(address(councilSafe), livenessGuardSlot))));
    }
}
