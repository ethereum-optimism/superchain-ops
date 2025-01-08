pragma solidity 0.8.15;

import {GenericTemplate} from "src/fps/example/templates/GenericTemplate.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";
import {ADDRESSES_PATH} from "src/fps/utils/Constants.sol";
import {OP_CHAIN_ID} from "src/fps/utils/Constants.sol";

interface IDeputyGuardian {
    function setRespectedGameType(address _portal, uint32 _gameType) external;
}

interface IOptimismPortal {
    function respectedGameType() external view returns (uint32);
}

contract Task02 is GenericTemplate {
    struct SetRespectedGameType {
        uint32 gameType;
        uint256 l2ChainId;
        string portal;
    }

    mapping(uint256 => SetRespectedGameType) public setRespectedGameTypes;

    function run(string memory taskConfigFilePath, string memory networkConfigFilePath) public override {
        SetRespectedGameType[] memory setRespectedGameType = abi.decode(
            vm.parseToml(vm.readFile(networkConfigFilePath), ".respectedGameTypes"), (SetRespectedGameType[])
        );

        for (uint256 i = 0; i < setRespectedGameType.length; i++) {
            setRespectedGameTypes[setRespectedGameType[i].l2ChainId] = setRespectedGameType[i];
        }

        super.run(taskConfigFilePath, networkConfigFilePath);
    }

    function _build(uint256 chainId) internal override {
        /// view only, filtered out by Proposal.sol
        IDeputyGuardian deputyGuardian = IDeputyGuardian(addresses.getAddress("DEPUTY_GUARDIAN", chainId));

        if (setRespectedGameTypes[chainId].l2ChainId != 0) {
            deputyGuardian.setRespectedGameType(
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

    function _mock(uint256 chainId) internal override {
        /// make the DEPUTY_GUARDIAN as a module to the Guardian safe
        bytes32 deputyGuardianModuleSlot =
            keccak256(abi.encode(addresses.getAddress("DEPUTY_GUARDIAN", chainId), uint256(1)));
        vm.store(
            addresses.getAddress("Guardian", chainId),
            deputyGuardianModuleSlot,
            bytes32(uint256(uint160(addresses.getAddress("DEPUTY_GUARDIAN", chainId))))
        );
    }
}
