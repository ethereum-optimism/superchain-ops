// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {AnchorStateRegistry} from "@eth-optimism-bedrock/src/dispute/AnchorStateRegistry.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    address immutable proxyAdminOwnerSafe = vm.envAddress("OWNER_SAFE");
    address immutable livenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;
    DisputeGameFactory constant DGF_PROXY = DisputeGameFactory(0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1);
    AnchorStateRegistry constant ASR_PROXY = AnchorStateRegistry(0x218CD9489199F321E1177b56385d333c5B598629);

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    FaultDisputeGame faultDisputeGame;

    /// @notice Sets up the faultDisputeGame
    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep/021-stage-1-4/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        faultDisputeGame = FaultDisputeGame(stdJson.readAddress(inputJson, "$.transactions[2].contractInputsValues._impl"));
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added, and they are allowed
        // to have code AND to have no code.
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();

        // To make sure we probably handle all signers whether or not they have code, first we count
        // the number of signers that have no code.
        uint256 numberOfSafeSignersWithNoCode;
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                numberOfSafeSignersWithNoCode++;
            }
        }

        // Then we extract those EOA addresses into a dedicated array.
        uint256 trackedSignersWithNoCode;
        address[] memory safeSignersWithNoCode = new address[](numberOfSafeSignersWithNoCode);
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                safeSignersWithNoCode[trackedSignersWithNoCode] = securityCouncilSafeOwners[i];
                trackedSignersWithNoCode++;
            }
        }

        // Here we add the standard (non Safe signer) exceptions.
        address[] memory shouldHaveCodeExceptions = new address[](0 + numberOfSafeSignersWithNoCode);


        // And finally, we append the Safe signer exceptions.
        for (uint256 i = 0; i < safeSignersWithNoCode.length; i++) {
            shouldHaveCodeExceptions[0 + i] = safeSignersWithNoCode[i];
        }

        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](6);
        allowed[0] = address(DGF_PROXY);
        allowed[1] = address(ASR_PROXY);
        allowed[2] = address(securityCouncilSafe);
        allowed[3] = address(fndSafe);
        allowed[4] = proxyAdminOwnerSafe;
        allowed[5] = livenessGuard;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxy();
        checkAsrProxy();
        console.log("All assertions passed!");
    }

    function checkDGFProxy() internal view {
        console.log("check dispute game implementations");
        require(address(faultDisputeGame) == address(DGF_PROXY.gameImpls(GameType.wrap(3))), "dgf-100");
    }

    function checkAsrProxy() internal view {
        console.log("check anchor state registry");
        (Hash root, uint256 num) = ASR_PROXY.anchors(GameType.wrap(3));
        require(root.raw() != bytes32(0), "asr-101");
        require(num != 0, "asr-102");
    }
}
