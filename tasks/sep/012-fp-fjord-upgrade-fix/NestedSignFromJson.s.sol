// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {LibString} from "solady/utils/LibString.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(0xf64bc17485f0B4Ea5F06A96514182FC4cB561977));

    // Known EOAs to exclude from safety checks.
    address constant l2OutputOracleProposer = 0x49277EE36A024120Ee218127354c4a3591dc90A9; // cast call $L2OO "PROPOSER()(address)"
    address constant l2OutputOracleChallenger = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant systemConfigOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant batchSenderAddress = 0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c; // In registry genesis-system-configs
    address constant p2pSequencerAddress = 0x57CACBB0d30b01eb2462e5dC940c161aff3230D3; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address constant batchInboxAddress = 0xff00000000000000000000000000000011155420; // In registry yaml.

    // Currenet dispute game implementations
    FaultDisputeGame currentFDG;
    PermissionedDisputeGame currentPDG;

    // New dispute game implementations
    FaultDisputeGame constant faultDisputeGame = FaultDisputeGame(0xA4E392d63AE6096DB5454Fa178E2F8f99F8eF0ef);
    PermissionedDisputeGame constant permissionedDisputeGame = PermissionedDisputeGame(0x864fbE13Bb239521a8c837A0aA7c7122ee3eb0b2);

    // See https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/extra/addresses/sepolia/op.json#L12
    DisputeGameFactory constant dgfProxy = DisputeGameFactory(0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1);

    // See https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/extra/addresses/sepolia/op.json#L14
    address constant delayedWethProxy = 0xF3D833949133e4E4D3551343494b34079598EA5a;

    function setUp() public {
        currentFDG = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        currentPDG = PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));

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

        require(address(faultDisputeGame.weth()) == delayedWethProxy, "precheck-100");
        require(address(permissionedDisputeGame.weth()) == delayedWethProxy, "precheck-100");

        require(address(currentFDG.vm()) == address(faultDisputeGame.vm()));

        // NOTE: This is what we're fixing. So they won't be equal
        //require(address(currentFDG.weth()) == address(faultDisputeGame.weth()));

        require(address(currentFDG.anchorStateRegistry()) == address(faultDisputeGame.anchorStateRegistry()));
        require(currentFDG.l2ChainId() == faultDisputeGame.l2ChainId());
        require(currentFDG.splitDepth() == faultDisputeGame.splitDepth());
        require(currentFDG.maxGameDepth() == faultDisputeGame.maxGameDepth());
        require(uint64(Duration.unwrap(currentFDG.maxClockDuration())) == uint64(Duration.unwrap(faultDisputeGame.maxClockDuration())));
        require(uint64(Duration.unwrap(currentFDG.clockExtension())) == uint64(Duration.unwrap(faultDisputeGame.clockExtension())));

        require(address(currentPDG.vm()) == address(permissionedDisputeGame.vm()));

        //require(address(currentPDG.weth()) == address(permissionedDisputeGame.weth())); // commented for now.

        require(address(currentPDG.anchorStateRegistry()) == address(permissionedDisputeGame.anchorStateRegistry()));
        require(currentPDG.l2ChainId() == permissionedDisputeGame.l2ChainId());
        require(currentPDG.splitDepth() == permissionedDisputeGame.splitDepth());
        require(currentPDG.maxGameDepth() == permissionedDisputeGame.maxGameDepth());
        require(uint64(Duration.unwrap(currentPDG.maxClockDuration())) == uint64(Duration.unwrap(permissionedDisputeGame.maxClockDuration())));
        require(uint64(Duration.unwrap(currentPDG.clockExtension())) == uint64(Duration.unwrap(permissionedDisputeGame.clockExtension())));
        require(address(currentPDG.proposer()) == address(permissionedDisputeGame.proposer()));
        require(address(currentPDG.challenger()) == address(permissionedDisputeGame.challenger()));
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

        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "check-100");
        require(address(permissionedDisputeGame) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "check-100");
    }
}
