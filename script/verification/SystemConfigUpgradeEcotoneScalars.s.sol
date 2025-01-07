// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ISystemConfig} from "./ISystemConfig.sol";
import {SystemConfigUpgrade} from "script/verification/SystemConfigUpgrade.s.sol";

// SystemConfigUpgradeEcotoneScalars is a contract that can be used to verify that an upgrade of the SystemConfig contract
// results in the correct values for scalar, basefeeScalar, and blobbasefeeScalar being set, and that the remaining
// storage values have not changed.
contract SystemConfigUpgradeEcotoneScalars is SystemConfigUpgrade {
    using LibString for string;

    constructor(string memory l1ChainName, string memory l2ChainName, string memory release)
        SystemConfigUpgrade(l1ChainName, l2ChainName, release)
    {}

    /// @notice Public function that must be called by the verification script.
    function checkSystemConfigUpgrade() public view override {
        ISystemConfig sysCfg = ISystemConfig(proxies.SystemConfig);
        uint256 reencodedScalar =
            (uint256(0x01) << 248) | (uint256(sysCfg.blobbasefeeScalar()) << 32) | sysCfg.basefeeScalar();
        console.log(
            "checking baseFeeScalar and blobbaseFeeScalar ",
            LibString.toString(sysCfg.basefeeScalar()),
            LibString.toString(sysCfg.blobbasefeeScalar())
        );
        if (
            uint8(previous.scalar >> 248) == 1 // most significant bit
        ) {
            console.log(
                "reencode to previous scalar: ",
                LibString.toString(reencodedScalar),
                LibString.toString(previous.scalar)
            );
            require(reencodedScalar == previous.scalar, "scalar-100 (reencoding produced incorrect result)");
            // We do this check last because it would fail if the scalar is wrong, and we get less debug info from it.
            // It checks all of the other fields which should not have changed (via a hash).
            super.checkSystemConfigUpgrade();
        }
        require(sysCfg.scalar() == reencodedScalar, "scalar-101");
    }
}
