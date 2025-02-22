// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {CouncilFoundationNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";

// Monorepo deps
import {IFaultDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IFaultDisputeGame.sol";
import {IPermissionedDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IPermissionedDisputeGame.sol";
import {IDisputeGameFactory} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {GameTypes, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {StandardValidatorV180} from "@eth-optimism-bedrock/src/L1/StandardValidator.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, CouncilFoundationNestedSign {

    IDisputeGameFactory constant OP_DGF = IDisputeGameFactory(0xF1408Ef0c263F8c42CefCc59146f90890615A191);
    ISystemConfig constant SYS_CFG = ISystemConfig(0x9FB5e819Fed7169a8Ff03F7fA84Ee29B876D61B4);
    IProxyAdmin constant PROXY_ADMIN_ADDRESS = IProxyAdmin(0xbD71120fC716a431AEaB81078ce85ccc74496552);
    IProxyAdmin constant SUPERCHAIN_PROXY_ADMIN = IProxyAdmin(0xFeE222a4FA606A9dD0B05CD0a8E1E40e60FD809a);

    mapping(IDisputeGameFactory => mapping(GameType => IFaultDisputeGame.GameConstructorParams)) public beforeParams;

    function setUp() public {
        addAllowedStorageAccess(address(OP_DGF));
        beforeParams[OP_DGF][GameTypes.PERMISSIONED_CANNON] =
            getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.PERMISSIONED_CANNON))));

        beforeParams[OP_DGF][GameTypes.CANNON] =
            getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.CANNON))));
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");

        // Does not work on Holesky because the addresses are not in the registry
        // accesses.decodeAndPrint();

        checkStateDiff(accesses);

        // get the before and after game params for the permissioned game
        IFaultDisputeGame.GameConstructorParams memory beforeParams_ =
            beforeParams[OP_DGF][GameTypes.PERMISSIONED_CANNON];
        IFaultDisputeGame.GameConstructorParams memory afterParams =
            getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.PERMISSIONED_CANNON))));
        // Set the before params to match the after params, since that is the only thing that should have
        // changed, the two sets of params should now have the same hash.
        beforeParams_.absolutePrestate = afterParams.absolutePrestate;
        require(
            keccak256(abi.encode(beforeParams_)) == keccak256(abi.encode(afterParams)),
            "Game params changed unexpectedly"
        );

        // get the before and after game params for the permissionless game
        beforeParams_ =
            beforeParams[OP_DGF][GameTypes.CANNON];
        afterParams =
            getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.CANNON))));
        // Set the before params to match the after params, since that is the only thing that should have
        // changed, the two sets of params should now have the same hash.
        beforeParams_.absolutePrestate = afterParams.absolutePrestate;
        require(
            keccak256(abi.encode(beforeParams_)) == keccak256(abi.encode(afterParams)),
            "Game params changed unexpectedly"
        );

        StandardValidatorV180 validator = StandardValidatorV180(0x3c6423ce73661f734f100a133fa996b5f07743c8);
        StandardValidatorV180.InputV180 input = StandardValidatorV180.InputV180({
            proxyAdmin: PROXY_ADMIN_ADDRESS,
            sysCfg: SYS_CFG,
            absolutePrestate: 0x03631bf3d25737500a4e483a8fd95656c68a68580d20ba1a5362cd6ba012a435,
            l2ChainID: 420110003
        });

        validator.validate(input);

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
