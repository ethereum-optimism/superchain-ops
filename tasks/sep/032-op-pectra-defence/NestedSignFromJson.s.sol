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
// import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {GameTypes, GameType, Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
// import {ISystemConfig} from "@eth-optimism-bedrock/interfaces/L1/ISystemConfig.sol";
import {StandardValidatorV180, IProxyAdmin, ISystemConfig} from "@eth-optimism-bedrock/src/L1/StandardValidator.sol";

import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, CouncilFoundationNestedSign {
    using AccountAccessParser for VmSafe.AccountAccess[];

    IDisputeGameFactory constant OP_DGF = IDisputeGameFactory(0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1);
    ISystemConfig constant SYS_CFG = ISystemConfig(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538);
    IProxyAdmin constant PROXY_ADMIN = IProxyAdmin(0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc);
    IProxyAdmin constant SUPERCHAIN_PROXY_ADMIN = IProxyAdmin(0xC2Be75506d5724086DEB7245bd260Cc9753911Be);

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

        // accesses.decodeAndPrint();

        checkStateDiff(accesses);

        // get the before and after game params for the permissioned game
        IFaultDisputeGame.GameConstructorParams memory beforeParams_ =
            beforeParams[OP_DGF][GameTypes.PERMISSIONED_CANNON];
        IFaultDisputeGame.GameConstructorParams memory afterParams =
            getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.PERMISSIONED_CANNON))));
        // Set the before prestate to match the after prestate, since that is the only thing that should have
        // changed, the two sets of params should now have the same hash.
        require(
            Claim.unwrap(beforeParams_.absolutePrestate) != Claim.unwrap(afterParams.absolutePrestate),
            "Prestate not updated"
        );
        require(
            Claim.unwrap(afterParams.absolutePrestate) == 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd,
            "Prestate not updated to expected value"
        );
        beforeParams_.absolutePrestate = afterParams.absolutePrestate;
        require(
            keccak256(abi.encode(beforeParams_)) == keccak256(abi.encode(afterParams)),
            "Game params changed unexpectedly"
        );

        // get the before and after game params for the permissionless game
        beforeParams_ = beforeParams[OP_DGF][GameTypes.CANNON];
        afterParams = getGameConstructorParams(IFaultDisputeGame(address(OP_DGF.gameImpls(GameTypes.CANNON))));
        // Set the before prestate to match the after prestate, since that is the only thing that should have
        // changed, the two sets of params should now have the same hash.
        beforeParams_.absolutePrestate = afterParams.absolutePrestate;
        require(
            keccak256(abi.encode(beforeParams_)) == keccak256(abi.encode(afterParams)),
            "Game params changed unexpectedly"
        );

        // Run StandardValidatorV180 to check that the chain config is valid
        StandardValidatorV180 validator = StandardValidatorV180(0x0A5bF8eBb4b177B2dcc6EbA933db726a2e2e2B4d);
        StandardValidatorV180.InputV180 memory input = StandardValidatorV180.InputV180({
            proxyAdmin: PROXY_ADMIN,
            sysCfg: SYS_CFG,
            absolutePrestate: 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd,
            l2ChainID: 11155420
        });

        console.log("Running StandardValidatorV180");
        string memory reasons = validator.validate({_input: input, _allowFailure: true});

        // We expect the following errors:
        // PDDG-20 - The permissioned game has a beta version suffix on Sepolia
        // PDDG-ANCHORP-40 - The anchor state registry's permissioned root is not 0xdead000000000000000000000000000000000000000000000000000000000000
        // PLDG-ANCHORP-40 - The anchor state registry's permissionless root is not 0xdead000000000000000000000000000000000000000000000000000000000000
        require(
            keccak256(bytes(reasons)) == keccak256(bytes("PDDG-20,PDDG-ANCHORP-40,PLDG-ANCHORP-40")),
            string.concat("Unexpected errors: ", reasons)
        );

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
