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
    address targetDGF;

    constructor(string memory _l1ChainName, string memory _l2ChainName, string memory _release)
        SystemConfigUpgrade(_l1ChainName, _l2ChainName, _release)
    {
        sysCfg = ISystemConfig(proxies.SystemConfig);
        previousScalar = sysCfg.scalar();

        if (sysCfg.version().eq("2.3.0")) {
            // Target Version
            targetDGF = sysCfg.disputeGameFactory();
        } else if (sysCfg.version().eq("2.2.0")) {
            // Supported initial version
            targetDGF = sysCfg.disputeGameFactory();
        } else if (sysCfg.version().eq("1.12.0")) {
            // Supported initial version
            targetDGF = address(0);
        } else {
            revert("unsupported SystemConfig version");
        }
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
            uint8(previousScalar >> 248) == 1
        ) {
            require(reencodedScalar == previousScalar, "scalar-100 scalar mismatch");
        } else {
            // Otherwise, if the scalar version is 0,
            // and the blobbasefeeScalar is 0,
            // the upgrade will migrate the scalar version to 1 and preserve
            // everything else.
            // See https://specs.optimism.io/protocol/system-config.html?highlight=ecotone%20scalar#ecotone-scalar-overhead-uint256uint256-change
            require(previousScalar >> 248 == 0, "scalar-101 previous scalar version != 0 or 1");
            require(reencodedScalar >> 248 == 1, "scalar-102 reenconded scalar version != 1");
            require(sysCfg.blobbasefeeScalar() == uint32(0), "scalar-103 blobbasefeeScalar !=0");
            require(reencodedScalar << 8 == previousScalar << 8, "scalar-104 scalar mismatch");
        }
        // Check that basefeeScalar and blobbasefeeScalar are correct by re-encoding them and comparing to the new scalar value.
        require(sysCfg.scalar() == reencodedScalar, "scalar-105");

        require(sysCfg.disputeGameFactory() == targetDGF, "scalar-106");

        // upgrade does not support CGT chains, so we require the gasPayingToken to be ETH
        (address t, uint8 d) = sysCfg.gasPayingToken();
        require(t == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "scalar-107");
        require(d == 18, "scalar-108");

        // Check remaining storage variables didn't change
        super.checkSystemConfigUpgrade();
    }
}
