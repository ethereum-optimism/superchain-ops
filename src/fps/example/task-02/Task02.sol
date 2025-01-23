pragma solidity 0.8.15;

import {GenericTemplate} from "src/fps/example/template/GenericTemplate.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

interface IDeputyGuardian {
    function setRespectedGameType(address _portal, uint32 _gameType) external;
}

interface IOptimismPortal {
    function respectedGameType() external view returns (uint32);
}

contract Task02 is GenericTemplate {
    struct SetRespectedGameType {
        address deputyGuardian;
        uint32 gameType;
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
            IDeputyGuardian(setRespectedGameTypes[chainId].deputyGuardian).setRespectedGameType(
                addresses.getAddress(setRespectedGameTypes[chainId].portal, chainId),
                setRespectedGameTypes[chainId].gameType
            );
        }
    }

    function _validate(uint256 chainId) internal view override {
        IOptimismPortal optimismPortal = IOptimismPortal(addresses.getAddress("OptimismPortalProxy", chainId));

        if (setRespectedGameTypes[chainId].l2ChainId != 0) {
            assertEq(optimismPortal.respectedGameType(), setRespectedGameTypes[chainId].gameType, "gameType not set");
        }
    }
}