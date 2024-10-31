// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
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
    address livenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;

    // Known EOAs to exclude from safety checks.
    address systemConfigOwner; // In registry addresses.
    address batchSenderAddress; // In registry genesis-system-configs
    address p2pSequencerAddress; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address batchInboxAddress; // In registry yaml.

    SystemConfig systemConfig = SystemConfig(vm.envAddress("SYSTEM_CONFIG"));

    // DisputeGameFactoryProxy address.
    DisputeGameFactory dgfProxy;

    function setUp() public {
        _getContractSet();

        dgfProxy = DisputeGameFactory(systemConfig.disputeGameFactory());
        // INSERT NEW PRE CHECKS HERE
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Owners of the nested safes will appear in storage in the LivenessGuard when added, and they are allowed
        // to have code AND to have no code.
        address[] memory nestedSafes = ownerSafe.getOwners();
        // First count the total owners from the nested safes
        uint256 totalNumberOfSigners;
        for (uint256 a = 0; a < nestedSafes.length; a++) {
            GnosisSafe safe = GnosisSafe(payable(nestedSafes[a]));
            totalNumberOfSigners += safe.getOwners().length;
        }
        address[] memory safeOwners = new address[](totalNumberOfSigners);
        uint256 addedSigners;
        for (uint256 a = 0; a < nestedSafes.length; a++) {
            GnosisSafe safe = GnosisSafe(payable(nestedSafes[a]));
            address[] memory nestedSafeOwners = safe.getOwners();
            for (uint256 i = 0; i < nestedSafeOwners.length; i++)  {
                safeOwners[addedSigners] = nestedSafeOwners[i];
                addedSigners++;
            }
        }

        // To make sure we probably handle all signers whether or not they have code, first we count
        // the number of signers that have no code.
        uint256 numberOfSafeSignersWithNoCode;
        for (uint256 i = 0; i < safeOwners.length; i++) {
            if (safeOwners[i].code.length == 0) {
                numberOfSafeSignersWithNoCode++;
            }
        }

        // Then we extract those EOA addresses into a dedicated array.
        uint256 trackedSignersWithNoCode;
        address[] memory safeSignersWithNoCode = new address[](numberOfSafeSignersWithNoCode);
        for (uint256 i = 0; i < safeOwners.length; i++) {
            if (safeOwners[i].code.length == 0) {
                safeSignersWithNoCode[trackedSignersWithNoCode] = safeOwners[i];
                trackedSignersWithNoCode++;
            }
        }

        // Here we add the standard (non Safe signer) exceptions.
        address[] memory shouldHaveCodeExceptions = new address[](4 + numberOfSafeSignersWithNoCode);

        shouldHaveCodeExceptions[0] = systemConfigOwner;
        shouldHaveCodeExceptions[1] = batchSenderAddress;
        shouldHaveCodeExceptions[2] = p2pSequencerAddress;
        shouldHaveCodeExceptions[3] = batchInboxAddress;

        // And finally, we append the Safe signer exceptions.
        for (uint256 i = 0; i < safeSignersWithNoCode.length; i++) {
            shouldHaveCodeExceptions[4 + i] = safeSignersWithNoCode[i];
        }

        return shouldHaveCodeExceptions;
    }

    // _precheckDisputeGameImplementation checks that the new game being set has the same configuration as the existing
    // implementation with the exception of the absolutePrestate. This is the most common scenario where the game
    // implementation is upgraded to provide an updated fault proof program that supports an upcoming hard fork.
    function _precheckDisputeGameImplementation(GameType _targetGameType, address _newImpl) internal view {
        console.log("pre-check new game implementations");

        FaultDisputeGame currentImpl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(_targetGameType))));
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

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        address[] memory nestedSafes = ownerSafe.getOwners();
        allowed = new address[](3 + nestedSafes.length);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
        allowed[2] = livenessGuard;
        for (uint256 i = 0; i < nestedSafes.length; i++) {
            allowed[3 + i] = nestedSafes[i];
        }
    }

    /// @notice Checks the correctness of the deployment
    function _nestedPostCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        // INSERT NEW POST CHECKS HERE

        console.log("All assertions passed!");
    }

    function _checkDisputeGameImplementation(GameType _targetGameType, address _newImpl) internal view {
        console.log("check dispute game implementations");

        require(_newImpl == address(dgfProxy.gameImpls(_targetGameType)), "check-100");
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/${l1ChainName}/${l2ChainName}.toml
    function _getContractSet() internal{
        // Read the known EOAs out of the systemConfig
        systemConfigOwner = systemConfig.owner();
        batchSenderAddress = address(uint160(uint256(systemConfig.batcherHash())));
        p2pSequencerAddress = systemConfig.unsafeBlockSigner();
        batchInboxAddress = systemConfig.batchInbox();
    }
}
