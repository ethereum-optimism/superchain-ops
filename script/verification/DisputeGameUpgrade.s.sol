// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {VerificationBase, SuperchainRegistry} from "script/verification/Verification.s.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";

interface IASR {
    function superchainConfig() external view returns (address superchainConfig_);
}

abstract contract DisputeGameUpgrade is VerificationBase, SuperchainRegistry {
    using LibString for string;

    bytes32 immutable expAbsolutePrestate;
    address immutable expFaultDisputeGame;
    address immutable expPermissionedDisputeGame;

    constructor(bytes32 _absolutePrestate, address _faultDisputeGame, address _permissionedDisputeGame) {
        expAbsolutePrestate = _absolutePrestate;
        expFaultDisputeGame = _faultDisputeGame;
        expPermissionedDisputeGame = _permissionedDisputeGame;

        addAllowedStorageAccess(proxies.DisputeGameFactory);
    }

    /// @notice Public function that must be called by the verification script.
    function checkDisputeGameUpgrade() public view {
        console.log("check dispute game implementations");

        DisputeGameFactory dgfProxy = DisputeGameFactory(proxies.DisputeGameFactory);
        FaultDisputeGame faultDisputeGame = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        PermissionedDisputeGame permissionedDisputeGame =
            PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));

        require(expFaultDisputeGame == address(faultDisputeGame), "game-100");
        require(expPermissionedDisputeGame == address(permissionedDisputeGame), "game-110");

        require(faultDisputeGame.version().eq(standardVersions.FaultDisputeGame.version), "game-200");
        require(permissionedDisputeGame.version().eq(standardVersions.PermissionedDisputeGame.version), "game-210");

        require(faultDisputeGame.absolutePrestate().raw() == expAbsolutePrestate, "game-300");
        require(permissionedDisputeGame.absolutePrestate().raw() == expAbsolutePrestate, "game-310");

        require(faultDisputeGame.l2ChainId() == chainConfig.chainId, "game-400");
        require(permissionedDisputeGame.l2ChainId() == chainConfig.chainId, "game-410");

        console.log("check mips");

        require(address(faultDisputeGame.vm()) == standardVersions.MIPS.Address, "mips-100");
        require(address(permissionedDisputeGame.vm()) == standardVersions.MIPS.Address, "mips-110");

        require(ISemver(standardVersions.MIPS.Address).version().eq(standardVersions.MIPS.version), "mips-200");
        require(
            address(MIPS(standardVersions.MIPS.Address).oracle()) == standardVersions.PreimageOracle.Address, "mips-300"
        );

        console.log("check anchor state registry");

        require(address(faultDisputeGame.anchorStateRegistry()) == proxies.AnchorStateRegistry, "asr-100");
        require(address(permissionedDisputeGame.anchorStateRegistry()) == proxies.AnchorStateRegistry, "asr-110");

        require(
            ISemver(proxies.AnchorStateRegistry).version().eq(standardVersions.AnchorStateRegistry.version), "asr-200"
        );
        require(IASR(proxies.AnchorStateRegistry).superchainConfig() == proxies.SuperchainConfig, "asr-300");

        console.log("check delayed weth");

        require(
            ISemver(address(faultDisputeGame.weth())).version().eq(standardVersions.DelayedWETH.version), "weth-100"
        );
        require(
            ISemver(address(permissionedDisputeGame.weth())).version().eq(standardVersions.DelayedWETH.version),
            "weth-110"
        );

        require(address(faultDisputeGame.weth()) != address(permissionedDisputeGame.weth()), "weth-200");
    }
}
