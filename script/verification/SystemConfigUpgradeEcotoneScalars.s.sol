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

    ISystemConfig sysCfg;
    uint256 previousScalar;

    constructor(string memory _l1ChainName, string memory _l2ChainName, string memory _release)
        SystemConfigUpgrade(_l1ChainName, _l2ChainName, _release)
    {
        sysCfg = ISystemConfig(proxies.SystemConfig);
        previousScalar = sysCfg.scalar();
    }

    /// @notice Public function that must be called by the verification script.
    function checkSystemConfigUpgrade() public view override {
        uint256 reencodedScalar =
            (uint256(0x01) << 248) | (uint256(sysCfg.blobbasefeeScalar()) << 32) | sysCfg.basefeeScalar();
        console.log(
            "checking baseFeeScalar and blobbaseFeeScalar ",
            LibString.toString(sysCfg.basefeeScalar()),
            LibString.toString(sysCfg.blobbasefeeScalar())
        );
        if (
            // If the scalar version (i.e. the most significant bit of the scalar)
            // is 1, we expect it to be unchanged during the upgrade.
            // Otherwise, the upgrade will migrate the scalar from version 0 to version 1
            uint8(previousScalar >> 248) == 1
        ) {
            require(reencodedScalar == previousScalar, "scalar-100 scalar mismatch");
        }
        require(sysCfg.scalar() == reencodedScalar, "scalar-101");
        super.checkSystemConfigUpgrade(); // check remaining storage variables didn't change
    }
}
