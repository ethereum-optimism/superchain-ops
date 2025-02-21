// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {VerificationBase} from "script/verification/Verification.s.sol";
import {CommonBase} from "forge-std/Base.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

contract NestedSignBase is VerificationBase, CommonBase {
    // The slot used to store the livenessGuard address in GnosisSafe.
    // See https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/base/GuardManager.sol#L30
    bytes32 constant livenessGuardSlot = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    function addSafe(GnosisSafe safe) internal {
        addAllowedStorageAccess(address(safe));
    }

    function addSafeWithLivenessGuard(GnosisSafe safe) internal {
        addSafe(safe);
        enableLivenessGuard(GnosisSafe(safe));
    }

    function enableLivenessGuard(GnosisSafe safe) private {
        addAllowedStorageAccess(livenessGuard(address(safe)));

        // livenessGuard potentially needs storage exceptions
        address[] memory securityCouncilSafeOwners = safe.getOwners();
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            address owner = securityCouncilSafeOwners[i];
            if (securityCouncilSafeOwners[i].code.length == 0) {
                addCodeException(owner);
            }
        }
    }

    function livenessGuard(address safe) internal view returns (address) {
        return address(uint160(uint256(vm.load(address(safe), livenessGuardSlot))));
    }
}

contract CouncilFoundationNestedSign is NestedSignBase {
    GnosisSafe immutable ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    GnosisSafe immutable councilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe immutable fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));

    constructor() {
        addSafe(ownerSafe);
        addSafe(fndSafe);
        addSafeWithLivenessGuard(councilSafe);
    }
}

contract CouncilFoundationGovernorNestedSign is CouncilFoundationNestedSign {
    GnosisSafe immutable governorSafe = GnosisSafe(payable(vm.envAddress("CHAIN_GOVERNOR_SAFE")));

    constructor(bool governorWithLivenessGuard) {
        if (governorWithLivenessGuard) {
            addSafeWithLivenessGuard(governorSafe);
        } else {
            addSafe(governorSafe);
        }
    }
}
