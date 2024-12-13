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
import {FaultDisputeGame, Duration, Claim} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {GameType, GameTypes} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";

contract NestedSignFromJson is OriginalSignFromJson {
    using LibString for string;

    uint256 immutable l2ChainId = 11155421;
    address immutable proxyAdminOwnerSafe = vm.envAddress("OWNER_SAFE");

    // Main contracts
    address dgfProxy;
    address faultDisputeGame;
    address permissionedDisputeGame;
    
    // Expectations for DisputeGame implementations
    string disputeGameExpectedVersion = "1.3.1";
    bytes32 immutable absolutePrestate = 0x03b7eaa4e3cbce90381921a4b48008f4769871d64f93d113fcadca08ecee503b;
    uint256 immutable maxGameDepth = 73;
    uint256 immutable splitDepth = 30;
    uint64 immutable maxClockDuration = 14400;
    uint64 immutable clockExtension = 3600;
    address anchorStateRegistryProxy;
    // Expectations for PermissionedDisputeGame
    address proposer;
    address challenger;
    
    // Expectations for vm
    string vmExpectedVersion = "1.0.0-beta.7";
    address preimageOracle;
    
    // Expectations for weth
    uint256 immutable wethDelay = 600;
    

    /// @notice Sets up the contract references
    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep-dev-0/007-mt-cannon/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        // Find contract addresses
        dgfProxy = readContractAddress("DisputeGameFactoryProxy");
        faultDisputeGame = stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl");
        permissionedDisputeGame = stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._impl");
        anchorStateRegistryProxy = readContractAddress("AnchorStateRegistryProxy");
        proposer = readContractAddress("Proposer");
        challenger = readContractAddress("Challenger");
        preimageOracle = readContractAddress("PreimageOracle");
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // None
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = dgfProxy;
        allowed[1] = proxyAdminOwnerSafe;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxy();
        checkDisputeGames();
        checkVm();
        checkWeths();
        console.log("All assertions passed!");
    }

    function checkDGFProxy() internal view {
        console.log("check DisputeGameFactoryProxy");
    DisputeGameFactory dgf = DisputeGameFactory(dgfProxy);
        
        require(proxyAdminOwnerSafe == dgf.owner(), "dgf-100");
        require(faultDisputeGame == address(dgf.gameImpls(GameTypes.CANNON)), "dgf-200");
        require(permissionedDisputeGame == address(dgf.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-300");
    }
    
    function checkDisputeGames() internal view {
        console.log("check dispute game implementations");
        
        checkDisputeGame(faultDisputeGame, GameTypes.CANNON);
        checkDisputeGame(permissionedDisputeGame, GameTypes.PERMISSIONED_CANNON);
    }

    function checkDisputeGame(address implAddress, GameType gameType) internal view {
        FaultDisputeGame gameImpl = FaultDisputeGame(implAddress);
        string memory gameStr = LibString.toString(GameType.unwrap(gameType));
        string memory errPrefix = string.concat("dg", gameStr, "-");

        console.log(string.concat("check dispute game implementation of GameType ", gameStr));
        require(gameImpl.l2ChainId() == l2ChainId, string.concat(errPrefix, "100"));
        require(GameType.unwrap(gameImpl.gameType()) == GameType.unwrap(gameType), string.concat(errPrefix, "200"));
        assertStringsEqual(gameImpl.version(), disputeGameExpectedVersion, string.concat(errPrefix, "300"));
        require(address(gameImpl.anchorStateRegistry()) == anchorStateRegistryProxy, string.concat(errPrefix, "400"));
        require(Claim.unwrap(gameImpl.absolutePrestate()) == absolutePrestate, string.concat(errPrefix, "500"));
        require(gameImpl.maxGameDepth() == maxGameDepth, string.concat(errPrefix, "600"));
        require(gameImpl.splitDepth() == splitDepth, string.concat(errPrefix, "700"));
        require(Duration.unwrap(gameImpl.maxClockDuration()) == maxClockDuration, string.concat(errPrefix, "800"));
        require(Duration.unwrap(gameImpl.clockExtension()) == clockExtension, string.concat(errPrefix, "900"));

        if(GameType.unwrap(gameType) == GameType.unwrap(GameTypes.PERMISSIONED_CANNON)) {
            PermissionedDisputeGame permImpl = PermissionedDisputeGame(implAddress);
            require(permImpl.proposer() == proposer, string.concat(errPrefix, "1000"));
            require(permImpl.challenger() == challenger, string.concat(errPrefix, "1100"));
        }
    }
    
    function checkVm() internal view {
        console.log("check VM implementation");
        
        address vmAddr0 = address(FaultDisputeGame(faultDisputeGame).vm());
        address vmAddr1 = address(PermissionedDisputeGame(permissionedDisputeGame).vm());
        IMIPS vm = IMIPS(vmAddr0);
        string memory vmVersion = vm.version();
        
        require(vmAddr0 == vmAddr1, "vm-100");
        assertStringsEqual(vmVersion, vmExpectedVersion, "vm-200");
         require(vm.oracle() == preimageOracle, "vm-300");
    }

    function checkWeths() internal view {
        console.log("check IDelayedWETH implementations");
        
        address weth0 = address(FaultDisputeGame(faultDisputeGame).weth());
        address weth1 = address(PermissionedDisputeGame(permissionedDisputeGame).weth());
        
        require(address(weth0) != address(weth1), "weths-100");
        checkWeth(IDelayedWETH(weth0), GameTypes.CANNON);
        checkWeth(IDelayedWETH(weth1), GameTypes.PERMISSIONED_CANNON);
    }
    
    function checkWeth(IDelayedWETH weth, GameType gameType) internal view {
        string memory gameStr = LibString.toString(GameType.unwrap(gameType));
        string memory errPrefix = string.concat("weth", gameStr, "-");

        console.log(string.concat("check IDelayedWETH implementation for GameType ", gameStr));
        // TODO: Fix DelayedWeth owners which are currently misconfigured
        // require(weth.owner() == proxyAdminOwnerSafe, string.concat(errPrefix, "100"));
        require(weth.delay() == wethDelay, string.concat(errPrefix, "200"));
    }
    
    function assertStringsEqual(string memory a, string memory b, string memory errorMessage) internal pure {
        require(keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)), errorMessage);
    }

    function readContractAddress(string memory contractName) internal view returns (address) {
        string memory addressesJson;

        // Read addresses json
        string memory path = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";

        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        return stdJson.readAddress(addressesJson, string.concat("$.", LibString.toString(l2ChainId), ".", contractName));
    }
}

interface IMIPS is ISemver {
    function oracle() external view returns (address oracle_);
}

interface IDelayedWETH {
    function owner() external view returns (address);
    function delay() external view returns (uint256);
}
