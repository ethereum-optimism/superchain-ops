// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {AnchorStateRegistry} from "@eth-optimism-bedrock/src/dispute/AnchorStateRegistry.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    DisputeGameFactory dgfProxy = DisputeGameFactory(0x2419423C72998eb1c6c15A235de2f112f8E38efF);
    AnchorStateRegistry asrProxy = AnchorStateRegistry(0x03b82AE60989863BCEb0BbD442A70568e5AefB85);

    // Safe contract for this task.
    address immutable proxyAdminOwnerSafe = vm.envAddress("OWNER_SAFE");
    address immutable livenessGuard = 0x24424336F04440b1c28685a38303aC33C9D14a25;

    FaultDisputeGame faultDisputeGame;

    /// @notice Sets up the faultDisputeGame
    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep-dev-0/007-stage-1-4/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        faultDisputeGame = FaultDisputeGame(stdJson.readAddress(inputJson, "$.transactions[2].contractInputsValues._impl"));
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        // No code exceptions expected
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](4);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(asrProxy);
        allowed[2] = proxyAdminOwnerSafe;
        allowed[3] = livenessGuard;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxy();
        checkAsrProxy();
        console.log("All assertions passed!");
    }

    function checkDGFProxy() internal view {
        console.log("check dispute game implementations");
        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameType.wrap(3))), "dgf-100");
    }

    function checkAsrProxy() internal view {
        console.log("check anchor state registry");
        (Hash root, uint256 num) = asrProxy.anchors(GameType.wrap(3));
        require(root.raw() != bytes32(0), "asr-101");
        require(num != 0, "asr-102");
    }
}
