// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";

contract NestedSignFromJson is OriginalSignFromJson {
    using LibString for string;

    DisputeGameFactory dgfProxy = DisputeGameFactory(0x2419423C72998eb1c6c15A235de2f112f8E38efF);

    // Safe contract for this task.
    address immutable proxyAdminOwnerSafe = vm.envAddress("OWNER_SAFE");
    address immutable livenessGuard = 0x24424336F04440b1c28685a38303aC33C9D14a25;

    FaultDisputeGame faultDisputeGame;
    PermissionedDisputeGame permissionedDisputeGame;

    /// @notice Sets up the dgfProxy
    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep-dev-0/004-fp-granite/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        address fdgAddress = stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl");
        address pdgAddress = stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._impl");
        faultDisputeGame = FaultDisputeGame(fdgAddress);
        permissionedDisputeGame = PermissionedDisputeGame(pdgAddress);
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        // No code exceptions expected
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](3);
        allowed[0] = address(dgfProxy);
        allowed[1] = proxyAdminOwnerSafe;
        allowed[2] = livenessGuard;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxy();
        console.log("All assertions passed!");
    }

    function checkDGFProxy() internal view {
        console.log("check dispute game implementations");
        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "dgf-100");
        require(address(permissionedDisputeGame) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-200");
    }
}
