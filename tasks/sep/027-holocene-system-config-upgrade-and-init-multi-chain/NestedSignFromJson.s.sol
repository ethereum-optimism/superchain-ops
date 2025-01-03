// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {DisputeGameUpgrade} from "script/verification/DisputeGameUpgrade.s.sol";
import {CouncilFoundationNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";
import {VerificationBase, SuperchainRegistry} from "script/verification/Verification.s.sol";
import {SystemConfigUpgradeEcotoneScalars as SystemConfigUpgrade} from
    "script/verification/SystemConfigUpgradeEcotoneScalars.s.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, CouncilFoundationNestedSign {
    string constant l1ChainName = "sepolia";
    string constant release = "v1.8.0-rc.4";
    string[4] l2ChainNames = ["op", "metal", "mode", "zora"];

    SystemConfigUpgrade[] sysCfgUpgrades;

    constructor() {
        for (uint256 i = 0; i < l2ChainNames.length; i++) {
            console.log("Setting up verification data for chain", l2ChainNames[i], "-", l1ChainName);
            sysCfgUpgrades.push(new SystemConfigUpgrade(l1ChainName, l2ChainNames[i], release));
            addAllowedStorageAccess(sysCfgUpgrades[i].systemConfigAddress());
            address[] memory exceptions = sysCfgUpgrades[i].getCodeExceptions();
            for (uint256 j = 0; j < exceptions.length; j++) {
                addCodeException(exceptions[j]);
            }
        }
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        for (uint256 i = 0; i < l2ChainNames.length; i++) {
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