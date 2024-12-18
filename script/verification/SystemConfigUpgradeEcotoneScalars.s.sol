// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {ISystemConfig} from "./ISystemConfig.sol";
import {IResourceMetering} from "./IResourceMetering.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {SystemConfigUpgrade} from "script/verification/SystemConfigUpgrade.s.sol";

contract SystemConfigUpgradeEcotoneScalars is SystemConfigUpgrade {
    using LibString for string;

    constructor(string memory l1ChainName, string memory l2ChainName, string memory release)
        SystemConfigUpgrade(l1ChainName, l2ChainName, release)
    {}

    /// @notice Public function that must be called by the verification script.
    function checkSystemConfigUpgrade() public view override {
        super.checkSystemConfigUpgrade();
        ISystemConfig sysCfg = ISystemConfig(proxies.SystemConfig);
        uint256 reencodedScalar =
            (uint256(0x01) << 248) | (uint256(sysCfg.blobbasefeeScalar()) << 32) | sysCfg.basefeeScalar();
        require(reencodedScalar == previous.scalar, "scalar-100");
    }
}
