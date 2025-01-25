// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {ISystemConfig, HoloceneSystemConfigUpgrade} from "script/verification/HoloceneSystemConfigUpgrade.s.sol";
import {VerificationBase} from "script/verification/Verification.s.sol";

contract SignFromJson is OriginalSignFromJson, VerificationBase {
    string constant l1ChainName = "sepolia";
    string constant release = "v1.8.0-rc.4";
    string constant l2ChainName = "base";

    address ownerSafe = vm.envAddress("OWNER_SAFE");

    HoloceneSystemConfigUpgrade sysCfgUpgrade;

    function setUp() public {
        sysCfgUpgrade = new HoloceneSystemConfigUpgrade(l1ChainName, l2ChainName, release);

        console.log("");
        console.log("Set up verification data for chain", l2ChainName, "-", l1ChainName);
        console.log("with SystemConfigProxy @", sysCfgUpgrade.systemConfigAddress());
        addAllowedStorageAccess(sysCfgUpgrade.systemConfigAddress());

        // The OwnerSafe multisig nonce is incremented.
        addAllowedStorageAccess(ownerSafe);

        addCodeExceptions(sysCfgUpgrade.getCodeExceptions());
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        sysCfgUpgrade.checkSystemConfigUpgrade();

        ISystemConfig systemConfig = ISystemConfig(sysCfgUpgrade.systemConfigAddress());
        vm.assertEq(systemConfig.eip1559Denominator(), 1, "incorrect EIP1559 denominator");
        vm.assertEq(systemConfig.eip1559Elasticity(), 4, "incorrect EIP1559 elasticity");

        console.log("All assertions passed!");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory) {
        return allowedStorageAccess;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        return codeExceptions;
    }
}
