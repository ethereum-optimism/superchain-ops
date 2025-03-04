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
    CouncilFoundationGovernorNestedSign
{
    uint256 constant initBond = 0.08 ether;
    string constant l1ChainName = "mainnet";
    string constant l2ChainName = "unichain";
    string constant release = "v1.8.0-rc.4";

    HoloceneSystemConfigUpgrade sysCfgUpgrade;

    constructor() CouncilFoundationGovernorNestedSign(true) {
        // Deploy a HoloceneSystemConfigUpgrade instance per chain,
        // which each contains its own bindings to an individual chain's SuperchainRegistry data.
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
    ) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
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
