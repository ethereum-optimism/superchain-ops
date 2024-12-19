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
import {LibString} from "solady/utils/LibString.sol";

abstract contract ProtocolVersionsBump is VerificationBase, SuperchainRegistry {
    struct ProtoVer {
        uint32 major;
        uint32 minor;
        uint32 patch;
        uint32 preRelease;
    }

    uint256 immutable newRecommendedProtocolVersion;
    uint256 immutable newRequiredProtocolVersion;

    // Safe contract for this task. TODO hardcode
    address foundationUpgradesSafe = vm.envAddress("FOUNDATION_SAFE");

    constructor(ProtoVer memory reccomended, ProtoVer memory required) {
        console.log(
            "Will validate ProtocolVersions bump to (reccommended,required): ",
            stringifyProtoVer(reccomended),
            stringifyProtoVer(required)
        );
        console.log(
            "Encoded versions are (reccommended,required): ",
            LibString.toHexString(encodeProtocolVersion(reccomended), 32),
            LibString.toHexString(encodeProtocolVersion(required), 32)
        );
        newRecommendedProtocolVersion = encodeProtocolVersion(reccomended);
        newRequiredProtocolVersion = encodeProtocolVersion(required);
        addAllowedStorageAccess(proxies.ProtocolVersions);
        addAllowedStorageAccess(foundationUpgradesSafe);
    }

    function stringifyProtoVer(ProtoVer memory pv) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                LibString.toString(pv.major),
                ".",
                LibString.toString(pv.minor),
                ".",
                LibString.toString(pv.patch),
                "-",
                LibString.toString(pv.preRelease)
            )
        );
    }

    function encodeProtocolVersion(ProtoVer memory pv) internal pure returns (uint256) {
        return
            (uint256(pv.major) << 96) | (uint256(pv.minor) << 64) | (uint256(pv.patch) << 32) | (uint256(pv.preRelease));
    }

    function checkProtocolVersions() public view {
        console.log("Checking ProtocolVersions at ", proxies.ProtocolVersions);
        ProtocolVersions pv = ProtocolVersions(proxies.ProtocolVersions);
        require(pv.owner() == foundationUpgradesSafe, "PV owner must be Foundation Upgrade Safe");
        require(ProtocolVersion.unwrap(pv.required()) == newRequiredProtocolVersion, "Required PV not set correctly");
        require(
            ProtocolVersion.unwrap(pv.recommended()) == newRecommendedProtocolVersion,
            "Recommended PV not set correctly"
        );
    }
}
