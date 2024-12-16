// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {AnchorStateRegistry} from "@eth-optimism-bedrock/src/dispute/AnchorStateRegistry.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    // Chains for this task.
    string l1ChainName = vm.envString("L1_CHAIN_NAME");
    string l2ChainName = vm.envString("L2_CHAIN_NAME");

    // Safe contract for this task.
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    GnosisSafe councilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe foundationSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));

    // The slot used to store the livenessGuard address in GnosisSafe.
    // See https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/base/GuardManager.sol#L30
    bytes32 livenessGuardSlot = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    SystemConfig systemConfig = SystemConfig(vm.envAddress("SYSTEM_CONFIG"));
    AnchorStateRegistry anchorStateRegistryProxy = AnchorStateRegistry(vm.envAddress("ANCHOR_STATE_REGISTRY"));
    address newFaultDisputeGameImpl = vm.envAddress("NEW_FAULT_DISPUTE_GAME_IMPL");
    address newPermissionedDisputeGameImpl = vm.envAddress("NEW_PERMISSIONED_DISPUTE_GAME_IMPL");
    bytes32 newAnchorStateRoot = vm.envBytes32("NEW_ANCHOR_STATE_ROOT");
    uint256 newAnchorStateBlockNumber = vm.envUint("NEW_ANCHOR_STATE_BLOCK_NUMBER");

    uint256 initBond = 0.08 ether;

    // DisputeGameFactoryProxy address.
    DisputeGameFactory dgfProxy;

    address[] extraStorageAccessAddresses;

    function setUp() public {
        require(address(anchorStateRegistryProxy.disputeGameFactory()) == address(systemConfig.disputeGameFactory()), "setup-100");
        dgfProxy = DisputeGameFactory(systemConfig.disputeGameFactory());
        extraStorageAccessAddresses.push(address(anchorStateRegistryProxy));
        _precheckAnchorStateCopy(GameType.wrap(1), GameType.wrap(0));
        _precheckDisputeGameImplementation(GameType.wrap(0), newFaultDisputeGameImpl);
        _precheckDisputeGameImplementation(GameType.wrap(1), newPermissionedDisputeGameImpl);
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added, and they are allowed
        // to have code AND to have no code.
        address[] memory securityCouncilSafeOwners = councilSafe.getOwners();

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
        address[] memory shouldHaveCodeExceptions = new address[](numberOfSafeSignersWithNoCode);
        // And finally, we append the Safe signer exceptions.
        for (uint256 i = 0; i < safeSignersWithNoCode.length; i++) {
            shouldHaveCodeExceptions[i] = safeSignersWithNoCode[i];
        }

        return shouldHaveCodeExceptions;
    }

    // _precheckDisputeGameImplementation checks that the new game being set has the same configuration as the existing
    // implementation with the exception of the absolutePrestate. This is the most common scenario where the game
    // implementation is upgraded to provide an updated fault proof program that supports an upcoming hard fork.
    function _precheckDisputeGameImplementation(GameType _targetGameType, address _newImpl) internal view {
        console.log("pre-check new game implementations", _targetGameType.raw());

        FaultDisputeGame currentImpl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(_targetGameType))));
        // No checks are performed if there is no prior implementation.
        // When deploying the first implementation, it is recommended to implement custom checks.
        if (address(currentImpl) == address(0)) {
            return;
        }
        FaultDisputeGame faultDisputeGame = FaultDisputeGame(_newImpl);
        require(address(currentImpl.vm()) == address(faultDisputeGame.vm()), "10");
        require(address(currentImpl.weth()) == address(faultDisputeGame.weth()), "20");
        require(address(currentImpl.anchorStateRegistry()) == address(faultDisputeGame.anchorStateRegistry()), "30");
        require(currentImpl.l2ChainId() == faultDisputeGame.l2ChainId(), "40");
        require(currentImpl.splitDepth() == faultDisputeGame.splitDepth(), "50");
        require(currentImpl.maxGameDepth() == faultDisputeGame.maxGameDepth(), "60");
        require(uint64(Duration.unwrap(currentImpl.maxClockDuration())) == uint64(Duration.unwrap(faultDisputeGame.maxClockDuration())), "70");
        require(uint64(Duration.unwrap(currentImpl.clockExtension())) == uint64(Duration.unwrap(faultDisputeGame.clockExtension())), "80");

        if (_targetGameType.raw() == GameTypes.PERMISSIONED_CANNON.raw()) {
            PermissionedDisputeGame currentPDG = PermissionedDisputeGame(address(currentImpl));
            PermissionedDisputeGame permissionedDisputeGame = PermissionedDisputeGame(address(faultDisputeGame));
            require(address(currentPDG.proposer()) == address(permissionedDisputeGame.proposer()), "90");
            require(address(currentPDG.challenger()) == address(permissionedDisputeGame.challenger()), "100");
        }
    }

    function _precheckAnchorStateCopy(GameType _fromType, GameType _toType) internal view {
        console.log("pre-check anchor state copy", _toType.raw());

        FaultDisputeGame fromImpl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(_fromType))));
        // Must have existing game type implementation for the source
        require(address(fromImpl) != address(0), "200");
        address fromRegistry = address(fromImpl.anchorStateRegistry());
        require(fromRegistry != address(0), "210");

        FaultDisputeGame toImpl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(_toType))));
        if (address(toImpl) != address(0)) {
            // If there is an existing implementation, it must use the same anchor state registry.
            address toRegistry = address(toImpl.anchorStateRegistry());
            require(toRegistry == fromRegistry, "210");
        }
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](5 + extraStorageAccessAddresses.length);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(councilSafe);
        allowed[3] = address(foundationSafe);
        address livenessGuard = address(uint160(uint256(vm.load(address(councilSafe), livenessGuardSlot))));
        allowed[4] = livenessGuard;

        for (uint256 i = 0; i < extraStorageAccessAddresses.length; i++) {
            allowed[5 + i] = extraStorageAccessAddresses[i];
        }
        return allowed;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _postcheckAnchorStateCopy(GameType.wrap(0), newAnchorStateRoot, newAnchorStateBlockNumber);
        _postcheckHasAnchorState(GameType.wrap(1));
        _checkDisputeGameImplementation(GameType.wrap(0), newFaultDisputeGameImpl);
        _checkDisputeGameImplementation(GameType.wrap(1), newPermissionedDisputeGameImpl);
        _checkInitBonds();

        console.log("All assertions passed!");
    }

    function _checkDisputeGameImplementation(GameType _targetGameType, address _newImpl) internal view {
        console.log("check dispute game implementations", _targetGameType.raw());

        require(_newImpl == address(dgfProxy.gameImpls(_targetGameType)), "check-100");
    }

    function _checkInitBonds() internal view {
        console.log("check the initial bonds");

        require(dgfProxy.initBonds(GameType.wrap(0)) == initBond, "check-bond-100");
        require(dgfProxy.initBonds(GameType.wrap(1)) == initBond, "check-bond-200");
    }

    function _postcheckAnchorStateCopy(GameType _gameType, bytes32 _root, uint256 _l2BlockNumber) internal view {
        console.log("check anchor state value", _gameType.raw());

        FaultDisputeGame impl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(_gameType))));
        (Hash root, uint256 rootBlockNumber) = FaultDisputeGame(address(impl)).anchorStateRegistry().anchors(_gameType);

        require(root.raw() == _root, "check-200");
        require(rootBlockNumber == _l2BlockNumber, "check-210");
    }

    // @notice Checks the anchor state for the source game type still exists after re-initialization.
    // The actual anchor state may have been updated since the task was defined so just assert it exists, not that
    // it has a specific value.
    function _postcheckHasAnchorState(GameType _gameType) internal view {
        console.log("check anchor state exists", _gameType.raw());

        FaultDisputeGame impl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(_gameType))));
        (Hash root, uint256 rootBlockNumber) = FaultDisputeGame(address(impl)).anchorStateRegistry().anchors(_gameType);

        require(root.raw() != bytes32(0), "check-300");
        require(rootBlockNumber != 0, "check-310");
    }
}
