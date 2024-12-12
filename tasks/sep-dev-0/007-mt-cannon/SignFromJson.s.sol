// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {GameType, GameTypes} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";

contract NestedSignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Safe contract for this task.
    address immutable proxyAdminOwnerSafe = vm.envAddress("OWNER_SAFE");
    
    DisputeGameFactory dgfProxy;
    FaultDisputeGame faultDisputeGame;
    PermissionedDisputeGame permissionedDisputeGame;

    /// @notice Sets up the contract references
    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep-dev-0/007-mt-cannon/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        string memory l2ChainId = "11155421";

        address dgfAddress = readContractAddress("DisputeGameFactoryProxy", l2ChainId);
        address fdgAddress = stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl");
        address pdgAddress = stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._impl");

        dgfProxy = DisputeGameFactory(dgfAddress);
        faultDisputeGame = FaultDisputeGame(fdgAddress);
        permissionedDisputeGame = PermissionedDisputeGame(pdgAddress);
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // None
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = address(dgfProxy);
        allowed[1] = proxyAdminOwnerSafe;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxy();
        checkDisputeGames();
        checkVm();
        console.log("All assertions passed!");
    }

    function checkDGFProxy() internal view {
        console.log("check DisputeGameFactoryProxy");
        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "dgf-100");
        require(address(permissionedDisputeGame) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-200");
    }
    
    function checkDisputeGames() internal view {
        console.log("check dispute game implementations");
        
        checkDisputeGame(address(faultDisputeGame), GameTypes.CANNON);
        checkDisputeGame(address(permissionedDisputeGame), GameTypes.PERMISSIONED_CANNON);
    }

    function checkDisputeGame(address implAddress, GameType gameType) internal view {
        FaultDisputeGame gameImpl = FaultDisputeGame(implAddress);
        string memory gameStr = LibString.toString(GameType.unwrap(gameType));
        string memory errPrefix = concat("dg", gameStr);

        console.log(concat("check dispute game implementation of type: ", gameStr));
        assertStringsEqual(gameImpl.version(), "1.3.1", concat(errPrefix, "100"));
    }
    
    function checkVm() internal view {
        console.log("check VM implementation");
        
        address vmAddr0 = address(faultDisputeGame.vm());
        address vmAddr1 = address(permissionedDisputeGame.vm());
        ISemver vm = ISemver(vmAddr0);
        string memory vmVersion = vm.version();
        
        require(vmAddr0 == vmAddr1, "vm-100");
        assertStringsEqual(vmVersion, "1.0.0-beta.7", "vm-200");
    }
    
    function assertStringsEqual(string memory a, string memory b, string memory errorMessage) internal pure {
        require(keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)), errorMessage);
    }
    
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function readContractAddress(string memory contractName, string memory chainId) internal view returns (address) {
        string memory addressesJson;

        // Read addresses json
        string memory path = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";

        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        return stdJson.readAddress(addressesJson, string.concat("$.", chainId, ".", contractName));
    }
}
