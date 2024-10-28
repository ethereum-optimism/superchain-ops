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

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    // Chains for this task.
    string l1ChainName = vm.envString("L1_CHAIN_NAME");
    string l2ChainName = vm.envString("L2_CHAIN_NAME");

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    address livenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;

    // Known EOAs to exclude from safety checks.
    address l2OutputOracleProposer; // cast call $L2OO "PROPOSER()(address)"
    address l2OutputOracleChallenger; // In registry addresses.
    address systemConfigOwner; // In registry addresses.
    address batchSenderAddress; // In registry genesis-system-configs
    address p2pSequencerAddress; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address batchInboxAddress; // In registry yaml.

    Types.ContractSet proxies;

    // Current dispute game implementation
    FaultDisputeGame currentImpl;

    // New dispute game implementation
    FaultDisputeGame faultDisputeGame;

    // Game type to set
    GameType targetGameType;

    // DisputeGameFactoryProxy address. Loaded from superchain-registry
    DisputeGameFactory dgfProxy;

    function setUp() public {
        proxies = _getContractSet();
        // Read the DisputeGameFactoryProxy and new dispute game implementation from the input JSON.
        string memory inputJson;
        string memory path = "/tasks/sep/fp-recovery/005-set-game-implementation/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        dgfProxy = DisputeGameFactory(stdJson.readAddress(inputJson, "$.transactions[0].to"));
        targetGameType = GameType.wrap(uint32(stdJson.readUint(inputJson, "$.transactions[0].contractInputsValues._gameType")));
        faultDisputeGame = FaultDisputeGame(stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl"));
        currentImpl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(targetGameType))));

        _precheckDisputeGameImplementation();
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

    function _precheckDisputeGameImplementation() internal view {
        console.log("pre-check new game implementations");

        if (address(currentImpl) == address(0)) {
            return;
        }
        require(address(currentImpl.vm()) == address(faultDisputeGame.vm()));
        require(address(currentImpl.weth()) == address(faultDisputeGame.weth()));
        require(address(currentImpl.anchorStateRegistry()) == address(faultDisputeGame.anchorStateRegistry()));
        require(currentImpl.l2ChainId() == faultDisputeGame.l2ChainId());
        require(currentImpl.splitDepth() == faultDisputeGame.splitDepth());
        require(currentImpl.maxGameDepth() == faultDisputeGame.maxGameDepth());
        require(uint64(Duration.unwrap(currentImpl.maxClockDuration())) == uint64(Duration.unwrap(faultDisputeGame.maxClockDuration())));
        require(uint64(Duration.unwrap(currentImpl.clockExtension())) == uint64(Duration.unwrap(faultDisputeGame.clockExtension())));

        if (targetGameType.raw() == GameTypes.PERMISSIONED_CANNON.raw()) {
            PermissionedDisputeGame currentPDG = PermissionedDisputeGame(address(currentImpl));
            PermissionedDisputeGame permissionedDisputeGame = PermissionedDisputeGame(address(faultDisputeGame));
            require(address(currentPDG.proposer()) == address(permissionedDisputeGame.proposer()));
            require(address(currentPDG.challenger()) == address(permissionedDisputeGame.challenger()));
        }
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](5);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(securityCouncilSafe);
        allowed[3] = address(fndSafe);
        allowed[4] = livenessGuard;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _checkDisputeGameImplementations();

        console.log("All assertions passed!");
    }

    function _checkDisputeGameImplementations() internal view {
        console.log("check dispute game implementations");

        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(targetGameType)), "check-100");
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/${l1ChainName}/${l2ChainName}.toml
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory chainConfig;

        // Read chain-specific config toml file
        string memory path = string.concat(
        "/lib/superchain-registry/superchain/configs/", l1ChainName, "/", l2ChainName, ".toml"
        );
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        // Read the known EOAs out of the config toml file
        l2OutputOracleProposer = stdToml.readAddress(chainConfig, "$.addresses.Proposer");
        l2OutputOracleChallenger = stdToml.readAddress(chainConfig, "$.addresses.Challenger");
        systemConfigOwner = stdToml.readAddress(chainConfig, "$.addresses.SystemConfigOwner");
        batchSenderAddress = stdToml.readAddress(chainConfig, "$.addresses.BatchSubmitter");
        p2pSequencerAddress = stdToml.readAddress(chainConfig, "$.addresses.UnsafeBlockSigner");
        batchInboxAddress = stdToml.readAddress(chainConfig, "$.batch_inbox_addr");

        // Read the chain-specific OptimismPortalProxy address
        _proxies.DisputeGameFactory = stdToml.readAddress(chainConfig, "$.addresses.DisputeGameFactoryProxy");
    }
}
