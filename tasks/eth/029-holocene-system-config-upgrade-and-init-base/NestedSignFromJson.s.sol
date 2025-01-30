// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {CouncilFoundationNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";
import {ISystemConfig, HoloceneSystemConfigUpgrade} from "script/verification/HoloceneSystemConfigUpgrade.s.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, CouncilFoundationNestedSign {
    string constant l1ChainName = "mainnet";
    string constant release = "v1.8.0-rc.4";
    string constant l2ChainName = "base";

    HoloceneSystemConfigUpgrade sysCfgUpgrade;

    constructor() {
        sysCfgUpgrade = new HoloceneSystemConfigUpgrade(l1ChainName, l2ChainName, release);
        console.log("");
        console.log("Set up verification data for chain", l2ChainName, "-", l1ChainName);
        console.log("with SystemConfigProxy @", sysCfgUpgrade.systemConfigAddress());
        addAllowedStorageAccess(sysCfgUpgrade.systemConfigAddress());
        addCodeExceptions(sysCfgUpgrade.getCodeExceptions());
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        sysCfgUpgrade.checkSystemConfigUpgradeWithPreviousGasLimitOverride(96_000_000);

        ISystemConfig systemConfig = ISystemConfig(sysCfgUpgrade.systemConfigAddress());
        vm.assertEq(systemConfig.eip1559Denominator(), 250, "incorrect EIP1559 denominator");
        vm.assertEq(systemConfig.eip1559Elasticity(), 2, "incorrect EIP1559 elasticity");

        vm.assertEq(systemConfig.blobbasefeeScalar(), 1055762, "incorrect blobbasefeeScalar");
        vm.assertEq(systemConfig.basefeeScalar(), 2269, "incorrect basefeeScalar");
        vm.assertEq(systemConfig.gasLimit(), 96000000, "incorrect gasLimit");

        console.log("All assertions passed!");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory) {
        return allowedStorageAccess;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        return codeExceptions;
    }
}
