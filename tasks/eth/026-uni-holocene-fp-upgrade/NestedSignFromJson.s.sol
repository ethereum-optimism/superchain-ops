// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {DisputeGameUpgrade} from "script/verification/DisputeGameUpgrade.s.sol";
import {AnchorStateRegistryAnchorUpdate, StartingAnchorRoot} from "script/verification/AnchorStateRegistry.s.sol";
import {CouncilFoundationGovernorNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";

contract NestedSignFromJson is
    OriginalNestedSignFromJson,
    CouncilFoundationGovernorNestedSign,
    DisputeGameUpgrade,
    AnchorStateRegistryAnchorUpdate
{
    uint256 constant initBond = 0.08 ether;

    constructor()
        CouncilFoundationGovernorNestedSign(true)
        SuperchainRegistry("mainnet", "uni", "v1.8.0-rc.4")
        DisputeGameUpgrade(
            0x0336751a224445089ba5456c8028376a0faf2bafa81d35f43fab8730258cdf37, // uni custom absolutePrestate
            0x08f0F8F4E792d21E16289dB7a80759323C446F61, // faultDisputeGame
            0xC457172937fFa9306099ec4F2317903254Bf7223 // permissionedDisputeGame
        )
        AnchorStateRegistryAnchorUpdate(_startingAnchorRoots())
    {}

    // compiles the array of StartingAnchorRoots for the constructor
    function _startingAnchorRoots() internal pure returns (StartingAnchorRoot[] memory sars_) {
        OutputRoot memory startingOutputRoot = OutputRoot({
            root: Hash.wrap(0xb5e152a45892717ad881031078cf0af24d224188cdaf1b16fcdba9657423c997),
            l2BlockNumber: 5619555
        });

        sars_ = new StartingAnchorRoot[](2);
        sars_[0] = StartingAnchorRoot({gameType: GameType.wrap(0), outputRoot: startingOutputRoot});
        sars_[1] = StartingAnchorRoot({gameType: GameType.wrap(1), outputRoot: startingOutputRoot});
    }

    function setUp() public view {
        checkInput();
    }

    function checkInput() public view {
        string memory inputJson;
        string memory path = "/tasks/eth/026-uni-holocene-fp-upgrade/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        address inputPermissionedDisputeGame =
            stdJson.readAddress(inputJson, "$.transactions[2].contractInputsValues._impl");
        address inputFaultDisputeGame = stdJson.readAddress(inputJson, "$.transactions[3].contractInputsValues._impl");
        require(expPermissionedDisputeGame == inputPermissionedDisputeGame, "input-pdg");
        require(expFaultDisputeGame == inputFaultDisputeGame, "input-fdg");
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkAnchorUpdates();
        checkDisputeGameUpgrade();
        _checkInitBonds();
        console.log("All assertions passed!");
    }

    function _checkInitBonds() internal view {
        console.log("check initial bonds");

        require(dgfProxy.initBonds(GameType.wrap(0)) == initBond, "bonds-10");
        require(dgfProxy.initBonds(GameType.wrap(1)) == initBond, "bonds-20");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory) {
        return allowedStorageAccess;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        return codeExceptions;
    }
}
