// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {VerificationBase, SuperchainRegistry} from "script/verification/Verification.s.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {ProtocolVersions, ProtocolVersion} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";

abstract contract ProtocolVersionsBump is VerificationBase, SuperchainRegistry {
    uint256 immutable newRecommendedProtocolVersion;
    uint256 immutable newRequiredProtocolVersion;

    // Safe contract for this task. TODO hardcode
    address foundationUpgradesSafe = vm.envAddress("FOUNDATION_SAFE");

    constructor(uint256 _newRecommendedProtocolVersion, uint256 _newRequiredProtocolVersion) {
        newRecommendedProtocolVersion = _newRecommendedProtocolVersion;
        newRequiredProtocolVersion = _newRequiredProtocolVersion;
        addAllowedStorageAccess(proxies.ProtocolVersions);
        addAllowedStorageAccess(foundationUpgradesSafe);
    }

    function checkProtocolVersions() public view {
        console.log("Checking ProtocolVersions at ", proxies.ProtocolVersions);
        ProtocolVersions pv = ProtocolVersions(proxies.ProtocolVersions);
        require(pv.owner() == foundationUpgradesSafe, "PV owner must be Foundation Upgrade Safe");
        require(ProtocolVersion.unwrap(pv.required()) == newRequiredProtocolVersion, "Required PV must be Holocene");
        require(
            ProtocolVersion.unwrap(pv.recommended()) == newRecommendedProtocolVersion,
            "Reccommended PV must be Holocene"
        );
    }
}
