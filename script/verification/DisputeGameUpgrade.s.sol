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
import {ISemver} from "@eth-optimism-bedrock/interfaces/universal/ISemver.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {Utils} from "src/libraries/Utils.sol";

interface IASR {
    function superchainConfig() external view returns (address superchainConfig_);
}

interface IMIPS is ISemver {
    function oracle() external view returns (address oracle_);
}

abstract contract DisputeGameUpgrade is VerificationBase, SuperchainRegistry {
    using LibString for string;

    bytes32 immutable expAbsolutePrestate;
    address immutable expFaultDisputeGame;
    address immutable expPermissionedDisputeGame;
    DisputeGameFactory immutable dgfProxy;

    constructor(bytes32 _absolutePrestate, address _faultDisputeGame, address _permissionedDisputeGame) {
        expAbsolutePrestate = _absolutePrestate;
        expFaultDisputeGame = _faultDisputeGame;
        expPermissionedDisputeGame = _permissionedDisputeGame;

        dgfProxy = DisputeGameFactory(proxies.DisputeGameFactory);

        addAllowedStorageAccess(proxies.DisputeGameFactory);

        precheckDisputeGames();
    }

    /// @notice Public function that must be called by the verification script.
    function checkDisputeGameUpgrade() public view {
        console.log("check dispute game implementations");

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

    function precheckDisputeGames() internal view {
        _precheckDisputeGameImplementation(GameType.wrap(0), expFaultDisputeGame);
        _precheckDisputeGameImplementation(GameType.wrap(1), expPermissionedDisputeGame);
    }

    // _precheckDisputeGameImplementation checks that the new game being set has the same
    // configuration as the existing implementation.
    function _precheckDisputeGameImplementation(GameType _targetGameType, address _newImpl) internal view {
        console.log("pre-check new game implementation", _targetGameType.raw());

        FaultDisputeGame currentGame = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(_targetGameType))));
        FaultDisputeGame newGame = FaultDisputeGame(_newImpl);

        if (Utils.isFeatureEnabled("DISPUTE_GAME_CHANGE_WETH")) {
            console.log("Expecting DelayedWETH to change");
            require(address(currentGame.weth()) != address(newGame.weth()), "pre-10");
        } else {
            console.log("Expecting DelayedWETH to stay the same");
            require(address(currentGame.weth()) == address(newGame.weth()), "pre-10");
        }

        require(_targetGameType.raw() == newGame.gameType().raw(), "pre-20");
        require(address(currentGame.anchorStateRegistry()) == address(newGame.anchorStateRegistry()), "pre-30");
        require(currentGame.l2ChainId() == newGame.l2ChainId(), "pre-40");
        require(currentGame.splitDepth() == newGame.splitDepth(), "pre-50");
        require(currentGame.maxGameDepth() == newGame.maxGameDepth(), "pre-60");
        require(currentGame.maxClockDuration().raw() == newGame.maxClockDuration().raw(), "pre-70");
        require(currentGame.clockExtension().raw() == newGame.clockExtension().raw(), "pre-80");

        if (_targetGameType.raw() == GameTypes.PERMISSIONED_CANNON.raw()) {
            PermissionedDisputeGame currentPDG = PermissionedDisputeGame(address(currentGame));
            PermissionedDisputeGame newPDG = PermissionedDisputeGame(address(newGame));
            require(address(currentPDG.proposer()) == address(newPDG.proposer()), "pre-90");
            require(address(currentPDG.challenger()) == address(newPDG.challenger()), "pre-100");
        }

        _precheckVm(newGame, currentGame);
    }

    // _precheckVm checks that the new VM has the same oracle as the old VM.
    function _precheckVm(FaultDisputeGame _newGame, FaultDisputeGame _currentGame) internal view {
        console.log("pre-check VM implementation", _newGame.gameType().raw());

        IMIPS newVm = IMIPS(address(_newGame.vm()));
        IMIPS currentVm = IMIPS(address(_currentGame.vm()));

        require(newVm.oracle() == currentVm.oracle(), "vm-10");
    }
}
