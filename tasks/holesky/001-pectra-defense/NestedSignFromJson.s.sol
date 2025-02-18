// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {CouncilFoundationNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";

// Monorepo deps
import {IFaultDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IFaultDisputeGame.sol";
import {IPermissionedDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IPermissionedDisputeGame.sol";
import {IDisputeGameFactory} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {GameTypes, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, CouncilFoundationNestedSign {
    using AccountAccessParser for VmSafe.AccountAccess[];

    IDisputeGameFactory constant OP_DGF = IDisputeGameFactory(0xF1408Ef0c263F8c42CefCc59146f90890615A191);

    mapping(IDisputeGameFactory => mapping(GameType => IFaultDisputeGame.GameConstructorParams)) public beforeParams;

    function setUp() public {
        addAllowedStorageAccess(address(OP_DGF));
        beforeParams[OP_DGF][GameTypes.PERMISSIONED_CANNON] =
            getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.PERMISSIONED_CANNON))));

        beforeParams[OP_DGF][GameTypes.CANNON] =
            getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.CANNON))));
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        accesses.decodeAndPrint();

        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        // get the game params
        IFaultDisputeGame.GameConstructorParams memory afterParams =
            getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.PERMISSIONED_CANNON))));
        IFaultDisputeGame.GameConstructorParams memory beforeParams_ = beforeParams[OP_DGF][GameTypes.PERMISSIONED_CANNON];
        beforeParams_.absolutePrestate = afterParams.absolutePrestate;
        require(keccak256(abi.encode(beforeParams_)) == keccak256(abi.encode(afterParams)), "Game params changed unexpectedly");

        console.log("All assertions passed!");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory) {
        return allowedStorageAccess;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        return codeExceptions;
    }

    function getGameConstructorParams(IFaultDisputeGame _disputeGame)
        internal
        view
        returns (IFaultDisputeGame.GameConstructorParams memory)
    {
        IFaultDisputeGame.GameConstructorParams memory params = IFaultDisputeGame.GameConstructorParams({
            gameType: _disputeGame.gameType(),
            absolutePrestate: _disputeGame.absolutePrestate(),
            maxGameDepth: _disputeGame.maxGameDepth(),
            splitDepth: _disputeGame.splitDepth(),
            clockExtension: _disputeGame.clockExtension(),
            maxClockDuration: _disputeGame.maxClockDuration(),
            vm: _disputeGame.vm(),
            weth: _disputeGame.weth(),
            anchorStateRegistry: _disputeGame.anchorStateRegistry(),
            l2ChainId: _disputeGame.l2ChainId()
        });
        return params;
    }
}
