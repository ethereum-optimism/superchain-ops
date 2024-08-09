// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {LibString} from "solady/utils/LibString.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "base";

    // Safe contract for this task.
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    // Known EOAs to exclude from safety checks.
    address constant l2OutputOracleProposer =
        0x20044a0d104E9e788A0C984A2B7eAe615afD046b; // cast call $L2OO "PROPOSER()(address)"
    address constant l2OutputOracleChallenger =
        0xDa3037Ff70Ac92CD867c683BD807e5A484857405; // In registry addresses.
    address constant systemConfigOwner =
        0x0fe884546476dDd290eC46318785046ef68a0BA9; // In registry addresses.
    address constant batchSenderAddress =
        0x6CDEbe940BC0F26850285cacA097C11c33103E47; // In registry genesis-system-configs
    address constant p2pSequencerAddress =
        0xb830b99c95Ea32300039624Cb567d324D4b1D83C; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address constant batchInboxAddress =
        0xfF00000000000000000000000000000000084532; // In registry yaml.
    address constant currentPDGProposer =
        0x727D7c7fCa14b7F3C49a1C816b42a41fe2F709F9;
    address constant currentPDGChallenger =
        0x8b8c52B04A38f10515C52670fcb23f3C4C44474F;

    // Currenet dispute game implementations
    FaultDisputeGame currentFDG;
    PermissionedDisputeGame currentPDG;

    // New dispute game implementations
    // https://sepolia.etherscan.io/address/0x48F9F3190b7B5231cBf2aD1A1315AF7f6A554020#code
    FaultDisputeGame constant faultDisputeGame =
        FaultDisputeGame(0x48F9F3190b7B5231cBf2aD1A1315AF7f6A554020);
    // https://sepolia.etherscan.io/address/0x54966d5A42a812D0dAaDe1FA2321FF8b102d1ee1#code
    PermissionedDisputeGame constant permissionedDisputeGame =
        PermissionedDisputeGame(0x54966d5A42a812D0dAaDe1FA2321FF8b102d1ee1);

    // See https://github.com/ethereum-optimism/superchain-registry/blob/0f5ca70fd3890ceb7f382beb0a5450ec4d45905d/superchain/extra/addresses/addresses.json#L266
    DisputeGameFactory constant dgfProxy =
        DisputeGameFactory(0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1);

    function setUp() public {
        currentFDG = FaultDisputeGame(
            address(dgfProxy.gameImpls(GameTypes.CANNON))
        );
        currentPDG = PermissionedDisputeGame(
            address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON))
        );

        _precheckDisputeGameImplementation();
    }

    function getCodeExceptions()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory shouldHaveCodeExceptions = new address[](4);

        shouldHaveCodeExceptions[0] = systemConfigOwner;
        shouldHaveCodeExceptions[1] = batchSenderAddress;
        shouldHaveCodeExceptions[2] = p2pSequencerAddress;
        shouldHaveCodeExceptions[3] = batchInboxAddress;

        return shouldHaveCodeExceptions;
    }

    function _precheckDisputeGameImplementation() internal view {
        console.log("pre-check new game implementations");

        require(address(currentFDG.vm()) == address(faultDisputeGame.vm()));
        require(address(currentFDG.weth()) == address(faultDisputeGame.weth()));
        require(
            address(currentFDG.anchorStateRegistry()) ==
                address(faultDisputeGame.anchorStateRegistry())
        );
        require(currentFDG.l2ChainId() == faultDisputeGame.l2ChainId());
        require(currentFDG.splitDepth() == faultDisputeGame.splitDepth());
        require(currentFDG.maxGameDepth() == faultDisputeGame.maxGameDepth());
        require(
            uint64(Duration.unwrap(currentFDG.maxClockDuration())) ==
                uint64(Duration.unwrap(faultDisputeGame.maxClockDuration()))
        );
        require(
            uint64(Duration.unwrap(currentFDG.clockExtension())) ==
                uint64(Duration.unwrap(faultDisputeGame.clockExtension()))
        );

        require(
            address(currentPDG.vm()) == address(permissionedDisputeGame.vm())
        );
        require(
            address(currentPDG.weth()) ==
                address(permissionedDisputeGame.weth())
        );
        require(
            address(currentPDG.anchorStateRegistry()) ==
                address(permissionedDisputeGame.anchorStateRegistry())
        );
        require(currentPDG.l2ChainId() == permissionedDisputeGame.l2ChainId());
        require(
            currentPDG.splitDepth() == permissionedDisputeGame.splitDepth()
        );
        require(
            currentPDG.maxGameDepth() == permissionedDisputeGame.maxGameDepth()
        );
        require(
            uint64(Duration.unwrap(currentPDG.maxClockDuration())) ==
                uint64(
                    Duration.unwrap(permissionedDisputeGame.maxClockDuration())
                )
        );
        require(
            uint64(Duration.unwrap(currentPDG.clockExtension())) ==
                uint64(
                    Duration.unwrap(permissionedDisputeGame.clockExtension())
                )
        );
        require(
            address(currentPDG.proposer()) ==
                address(permissionedDisputeGame.proposer())
        );
        require(address(currentPDG.challenger()) == currentPDGProposer);
        require(
            address(permissionedDisputeGame.challenger()) ==
                currentPDGChallenger
        );
    }

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory allowed)
    {
        allowed = new address[](2);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(
        Vm.AccountAccess[] memory accesses,
        SimulationPayload memory /* simPayload */
    ) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _checkDisputeGameImplementations();

        console.log("All assertions passed!");
    }

    function _checkDisputeGameImplementations() internal view {
        console.log("check dispute game implementations");

        require(
            address(faultDisputeGame) ==
                address(dgfProxy.gameImpls(GameTypes.CANNON)),
            "check-100"
        );
        require(
            address(permissionedDisputeGame) ==
                address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)),
            "check-100"
        );
        require(
            faultDisputeGame.absolutePrestate().raw() ==
                bytes32(
                    0x030de10d9da911a2b180ecfae2aeaba8758961fc28262ce989458c6f9a547922
                )
        );
        require(
            permissionedDisputeGame.absolutePrestate().raw() ==
                bytes32(
                    0x030de10d9da911a2b180ecfae2aeaba8758961fc28262ce989458c6f9a547922
                )
        );
    }
}
