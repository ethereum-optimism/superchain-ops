// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import {BytecodeComparison} from "src/libraries/BytecodeComparison.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Types} from "@eth-optimism-bedrock/scripts/libraries/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {ISemver} from "@eth-optimism-bedrock/interfaces/universal/ISemver.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, SuperchainRegistry {
    using LibString for string;

    /// Dynamically assigned to the addresses in setUp
    DisputeGameFactory dgfProxy;
    address newMips;
    address oracle;
    uint256 chainId;

    //DisputeGameFactory constant dgfProxy = DisputeGameFactory(0x860e626c700AF381133D9f4aF31412A2d1DB3D5d);
    address constant livenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;
    bytes32 constant absolutePrestate = 0x03dfa3b3ac66e8fae9f338824237ebacff616df928cf7dada0e14be2531bc1f4;
    //address constant newMips = 0x69470D6970Cd2A006b84B1d4d70179c892cFCE01;
    //address constant oracle = 0x92240135b46fc1142dA181f550aE8f595B858854;
    string constant gameVersion = "1.3.1";
    //uint256 constant chainId = 763373;

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    FaultDisputeGame faultDisputeGame;
    PermissionedDisputeGame permissionedDisputeGame;

    constructor() SuperchainRegistry("sepolia", "ink", "v1.8.0-rc.4") {}

    function setUp() public {
        
        console.log("Fetching DisputeGameFactory address...");
        dgfProxy = DisputeGameFactory(proxies.DisputeGameFactory);
        console.log("DisputeGameFactory Proxy Address:", address(dgfProxy));

        console.log("Fetching newMips address...");
        newMips = standardVersions.MIPS.Address;
        console.log("Fetched newMips Address:", newMips);

        console.log("Fetching oracle address...");
        oracle = standardVersions.PreimageOracle.Address;
        console.log("Fetched Oracle Address:", oracle);

        console.log("Fetching chainId...");
        chainId = chainConfig.chainId;
        console.log("Fetched Chain ID:", chainId);

        string memory inputJson;
        string memory path = "/tasks/sep/ink-001-fp-holocene-pectra-upgrade/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        permissionedDisputeGame = PermissionedDisputeGame(stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl"));
        faultDisputeGame = FaultDisputeGame(stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._impl"));
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
        allowed = new address[](5);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(securityCouncilSafe);
        allowed[3] = address(fndSafe);
        allowed[4] = livenessGuard;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxyAndGames();
        checkMips();
        console.log("All assertions passed!");
    }

    function checkDGFProxyAndGames() internal view {
        console.log("check dispute game implementations");
        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "dgf-100");
        require(address(permissionedDisputeGame) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-200");

        require(faultDisputeGame.version().eq(gameVersion), "game-100");
        require(permissionedDisputeGame.version().eq(gameVersion), "game-200");

        require(faultDisputeGame.absolutePrestate().raw() == absolutePrestate, "game-300");
        require(permissionedDisputeGame.absolutePrestate().raw() == absolutePrestate, "game-400");

        require(address(faultDisputeGame.vm()) == newMips, "game-500");
        require(address(permissionedDisputeGame.vm()) == newMips, "game-600");

        require(faultDisputeGame.l2ChainId() == chainId, "game-700");
        require(permissionedDisputeGame.l2ChainId() == chainId, "game-800");
    }

    function checkMips() internal view{
        console.log("check MIPS");

        require(newMips.code.length != 0, "MIPS-100");
        vm.assertEq(ISemver(newMips).version(), "1.2.1");
        require(address(MIPS(newMips).oracle()) == oracle, "MIPS-200");
    }

}
