// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {DisputeGameUpgrade} from "script/verification/DisputeGameUpgrade.s.sol";
import {CouncilFoundationNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, CouncilFoundationNestedSign, DisputeGameUpgrade {
    constructor()
        SuperchainRegistry("sepolia", "op", "v1.8.0-rc.4")
        DisputeGameUpgrade(
            0x03b7eaa4e3cbce90381921a4b48008f4769871d64f93d113fcadca08ecee503b, // absolutePrestate
            0x833a817eF459f4eCdB83Fc5A4Bf04d09A4e83f3F, // faultDisputeGame
            0xbBD576128f71186A0f9ae2F2AAb4afb4aF2dae17 // permissionedDisputeGame
        )
    {}

    function setUp() public view {
        checkInput();
    }

    function checkInput() public view {
        string memory inputJson;
        string memory path = "/tasks/sep/026-fp-holocene-upgrade-fix/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        address inputPermissionedDisputeGame =
            stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl");
        address inputFaultDisputeGame = stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._impl");
        require(expPermissionedDisputeGame == inputPermissionedDisputeGame, "input-pdg");
        require(expFaultDisputeGame == inputFaultDisputeGame, "input-fdg");
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDisputeGameUpgrade();
        console.log("All assertions passed!");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory) {
        return allowedStorageAccess;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        return codeExceptions;
    }
}
