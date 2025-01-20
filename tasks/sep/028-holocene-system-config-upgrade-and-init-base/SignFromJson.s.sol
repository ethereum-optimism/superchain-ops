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

        // The last call to initialize:
        //  1. resets the owner temporarily to the caller (ProxyAdmin@0x0389e59aa0a41e4a413ae70f0008e76caa34b1f3) when calling `__Ownable_init()`
        //     https://github.com/ethereum-optimism/optimism/blob/39e9f1a4693912af8bdef428d246c15a6cf44ec7/packages/contracts-bedrock/src/L1/SystemConfig.sol#L171
        //     This in turn runs the code at https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/d2ec96a77f25bd095bcf0d0e1e0b56be3f6be711/contracts/access/OwnableUpgradeable.sol#L29
        //
        //  2. sets the owner back to the OwnerSafe multisig when calling `transferOwnership(_owner)`
        //     https://github.com/ethereum-optimism/optimism/blob/39e9f1a4693912af8bdef428d246c15a6cf44ec7/packages/contracts-bedrock/src/L1/SystemConfig.sol#L172
        //
        //  /!\ For this reason we need NOT to include the code exception for the OwnerSafe multisig /!\
        address[] memory codeExceptions = sysCfgUpgrade.getCodeExceptions();
        for (uint256 i; i < codeExceptions.length; i++) {
            if (codeExceptions[i] == ownerSafe) {
                continue;
            }

            addCodeException(codeExceptions[i]);
        }
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        sysCfgUpgrade.checkSystemConfigUpgrade();

        ISystemConfig systemConfig = ISystemConfig(sysCfgUpgrade.systemConfigAddress());
        vm.assertEq(systemConfig.eip1559Denominator(), 1, "invalid EIP1559 denominator");
        vm.assertEq(systemConfig.eip1559Elasticity(), 4, "invalid EIP1559 elasticity");

        console.log("All assertions passed!");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory) {
        return allowedStorageAccess;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        return codeExceptions;
    }
}
