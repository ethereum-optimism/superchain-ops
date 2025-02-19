// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {DisputeGameUpgrade} from "script/verification/DisputeGameUpgrade.s.sol";
import {CouncilFoundationGovernorNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";
import {VerificationBase, SuperchainRegistry} from "script/verification/Verification.s.sol";
import {HoloceneSystemConfigUpgrade} from "script/verification/HoloceneSystemConfigUpgrade.s.sol";

contract NestedSignFromJson is
    OriginalNestedSignFromJson,
    CouncilFoundationGovernorNestedSign,
    DisputeGameUpgrade
{
    uint256 constant initBond = 0.08 ether;
    // string constant l1ChainName = "mainnet";
    string constant release = "v1.8.0-rc.4";
    // string[1] l2ChainNames = ["unichain"];

    bytes32 constant ABSOLUTE_PRESTATE =
        0x0336751a224445089ba5456c8028376a0faf2bafa81d35f43fab8730258cdf37;
    address constant FAULT_DISPUTE_GAME =
        0x08f0F8F4E792d21E16289dB7a80759323C446F61;
    address constant PERMISSIONED_DISPUTE_GAME =
        0x2B9fD545CcFC6611E5F1e3bb52840010aA64C5C6;

    HoloceneSystemConfigUpgrade sysCfgUpgrade;

    constructor()
        CouncilFoundationGovernorNestedSign(true)
        SuperchainRegistry("mainnet", "unichain", "v1.8.0-rc.4")
        DisputeGameUpgrade(
            ABSOLUTE_PRESTATE, // uni custom absolutePrestate
            FAULT_DISPUTE_GAME, // faultDisputeGame (same)
            PERMISSIONED_DISPUTE_GAME // permissionedDisputeGame (new)
        )
    {
        sysCfgUpgrade = new HoloceneSystemConfigUpgrade(
            l1ChainName,
            l2ChainName,
            release
        );
        console.log("");
        console.log(
            "Set up verification data for chain",
            l2ChainName,
            "-",
            l1ChainName
        );
        console.log(
            "with SystemConfigProxy @",
            sysCfgUpgrade.systemConfigAddress()
        );
        addAllowedStorageAccess(sysCfgUpgrade.systemConfigAddress());
        addCodeExceptions(sysCfgUpgrade.getCodeExceptions());
    }

    function _postCheck(
        Vm.AccountAccess[] memory accesses,
        Simulation.Payload memory
    ) internal override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        console.log("");
        console.log(
            "Running post-deploy assertions for chain",
            l2ChainName,
            "-",
            l1ChainName
        );
        sysCfgUpgrade.checkSystemConfigUpgrade();
        console.log("All assertions passed!");
    }

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory)
    {
        return allowedStorageAccess;
    }

    function getCodeExceptions()
        internal
        view
        override
        returns (address[] memory)
    {
        return codeExceptions;
    }
}
