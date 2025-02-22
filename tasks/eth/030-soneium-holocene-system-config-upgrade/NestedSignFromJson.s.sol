// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {CouncilFoundationNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";
import {VerificationBase, SuperchainRegistry} from "script/verification/Verification.s.sol";
import {HoloceneSystemConfigUpgrade} from "script/verification/HoloceneSystemConfigUpgrade.s.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, CouncilFoundationNestedSign {
    string constant l1ChainName = "mainnet";
    string constant release = "v1.8.0-rc.4";
    string[1] l2ChainNames = ["soneium"];

    HoloceneSystemConfigUpgrade[] sysCfgUpgrades;

    constructor() {
        for (uint256 i = 0; i < l2ChainNames.length; i++) {
            // Deploy a HoloceneSystemConfigUpgrade instance per chain,
            // which each contains its own bindings to an individual chain's SuperchainRegistry data.
            sysCfgUpgrades.push(new HoloceneSystemConfigUpgrade(l1ChainName, l2ChainNames[i], release));
            console.log("");
            console.log("Set up verification data for chain", l2ChainNames[i], "-", l1ChainName);
            console.log("with SystemConfigProxy @", sysCfgUpgrades[i].systemConfigAddress());
            addAllowedStorageAccess(sysCfgUpgrades[i].systemConfigAddress());
            addCodeExceptions(sysCfgUpgrades[i].getCodeExceptions());
        }
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        for (uint256 i = 0; i < sysCfgUpgrades.length; i++) {
            console.log("");
            console.log("Running post-deploy assertions for chain", l2ChainNames[i], "-", l1ChainName);
            sysCfgUpgrades[i].checkSystemConfigUpgrade();
        }
        console.log("All assertions passed!");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory) {
        return allowedStorageAccess;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        return codeExceptions;
    }
}
