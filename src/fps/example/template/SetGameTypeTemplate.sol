pragma solidity 0.8.15;

import {
    DeputyGuardianModule, IOptimismPortal2, GameType
} from "@eth-optimism-bedrock/src/safe/DeputyGuardianModule.sol";
import {LibGameType} from "@eth-optimism-bedrock/src/dispute/lib/LibUDT.sol";

import {GenericTemplate} from "src/fps/example/template/GenericTemplate.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

contract SetGameTypeTemplate is GenericTemplate {
    using LibGameType for GameType;

    struct SetRespectedGameType {
        address deputyGuardian;
        GameType gameType;
        uint256 l2ChainId;
        string portal;
    }

    mapping(uint256 => SetRespectedGameType) public setRespectedGameTypes;

    function _templateSetup(string memory, string memory networkConfigFilePath, Addresses) internal override {
        SetRespectedGameType[] memory setRespectedGameType = abi.decode(
            vm.parseToml(vm.readFile(networkConfigFilePath), ".respectedGameTypes"), (SetRespectedGameType[])
        );

        for (uint256 i = 0; i < setRespectedGameType.length; i++) {
            setRespectedGameTypes[setRespectedGameType[i].l2ChainId] = setRespectedGameType[i];
        }
    }

    function _build(uint256 chainId) internal override {
        if (setRespectedGameTypes[chainId].l2ChainId != 0) {
            DeputyGuardianModule(setRespectedGameTypes[chainId].deputyGuardian).setRespectedGameType(
                IOptimismPortal2(payable(addresses.getAddress(setRespectedGameTypes[chainId].portal, chainId))),
                setRespectedGameTypes[chainId].gameType
            );
        }
    }

    function _validate(uint256 chainId) internal view override {
        IOptimismPortal2 optimismPortal =
            IOptimismPortal2(payable(addresses.getAddress("OptimismPortalProxy", chainId)));

        if (setRespectedGameTypes[chainId].l2ChainId != 0) {
            assertEq(
                optimismPortal.respectedGameType().raw(),
                setRespectedGameTypes[chainId].gameType.raw(),
                "gameType not set"
            );
        }
    }
}
