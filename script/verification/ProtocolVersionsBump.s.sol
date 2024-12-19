// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {VerificationBase, SuperchainRegistry} from "script/verification/Verification.s.sol";
import {ProtocolVersions, ProtocolVersion} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {LibString} from "solady/utils/LibString.sol";

abstract contract ProtocolVersionsBump is VerificationBase, SuperchainRegistry {
    struct ProtoVer {
        uint32 major;
        uint32 minor;
        uint32 patch;
        uint32 preRelease;
    }

    uint256 immutable reccomended;
    uint256 immutable required;

    address owner;

    constructor(address _owner, ProtoVer memory _recommended, ProtoVer memory _required) {
        owner = _owner;
        console.log("Current owner is:", owner);
        reccomended = encodeProtocolVersion(_recommended);
        required = encodeProtocolVersion(_required);
        console.log(
            "Will validate ProtocolVersions bump to (reccommended,required): ",
            stringifyProtoVer(_recommended),
            stringifyProtoVer(_required)
        );
        console.log(
            "Encoded versions are (reccommended,required): ",
            LibString.toHexString(reccomended, 32),
            LibString.toHexString(required, 32)
        );
        addAllowedStorageAccess(proxies.ProtocolVersions);
        addAllowedStorageAccess(owner);
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
        require(pv.owner() == owner, "PV.owner not expected");
        require(ProtocolVersion.unwrap(pv.required()) == required, "Required PV not set correctly");
        require(ProtocolVersion.unwrap(pv.recommended()) == reccomended, "Recommended PV not set correctly");
    }
}
