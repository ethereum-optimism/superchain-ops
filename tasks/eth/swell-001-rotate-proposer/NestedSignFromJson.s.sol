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
    address newPermissionedDisputeGameImpl = vm.envAddress("NEW_PERMISSIONED_DISPUTE_GAME_IMPL");
    address newProposerAddress = vm.envAddress("NEW_PROPOSER_ADDRESS");

    uint256 initBond = 0.08 ether;

    // DisputeGameFactoryProxy address.
    DisputeGameFactory dgfProxy;

    // address[] extraStorageAccessAddresses;

    function setUp() public {
        dgfProxy = DisputeGameFactory(systemConfig.disputeGameFactory());
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
            require(address(currentPDG.challenger()) == address(permissionedDisputeGame.challenger()), "90");
            // require(address(currentPDG.proposer()) == address(permissionedDisputeGame.proposer()), "90");
            // Swell Mainnet is rotating its proposer keys to the ones specified here: https://alt-research.notion.site/Rotate-proposer-key-for-Swell-mainnet-1cfd3246cc8c806681bbd38d52a0d969
            require(address(permissionedDisputeGame.proposer()) == newProposerAddress, "100");
        }
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        // allowed = new address[](5 + extraStorageAccessAddresses.length);
        allowed = new address[](5);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(councilSafe);
        allowed[3] = address(foundationSafe);
        address livenessGuard = address(uint160(uint256(vm.load(address(councilSafe), livenessGuardSlot))));
        allowed[4] = livenessGuard;

        // for (uint256 i = 0; i < extraStorageAccessAddresses.length; i++) {
        //     allowed[5 + i] = extraStorageAccessAddresses[i];
        // }
        return allowed;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _checkDisputeGameImplementation(GameType.wrap(1), newPermissionedDisputeGameImpl);

        console.log("All assertions passed!");
    }

    function _checkDisputeGameImplementation(GameType _targetGameType, address _newImpl) internal view {
        console.log("check dispute game implementations", _targetGameType.raw());

        require(_newImpl == address(dgfProxy.gameImpls(_targetGameType)), "check-100");
    }
}
