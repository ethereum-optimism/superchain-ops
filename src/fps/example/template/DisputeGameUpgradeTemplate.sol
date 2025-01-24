pragma solidity 0.8.15;

import {IDisputeGameFactory, IDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

contract DisputeGameUpgradeTemplate is MultisigTask {
    /// @notice struct to store information about an implementation to be set for a specific l2 chain id
    struct SetImplementation {
        GameType gameType;
        address implementation;
        uint256 l2ChainId;
    }

    /// @notice maps a l2 chain id to a SetImplementation struct
    mapping(uint256 => SetImplementation) public setImplementations;

    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    function taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    function _templateSetup(string memory taskConfigFilePath) internal override {
        SetImplementation[] memory setImplementation =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".implementations"), (SetImplementation[]));

        for (uint256 i = 0; i < setImplementation.length; i++) {
            setImplementations[setImplementation[i].l2ChainId] = setImplementation[i];
        }
    }

    /// @notice builds setImplementation action for the given chainId. Overrrides MultisigTask._build
    function _build(uint256 chainId) internal override {
        /// view only, filtered out by Proposal.sol
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(addresses.getAddress("DisputeGameFactoryProxy", chainId));

        if (setImplementations[chainId].l2ChainId != 0) {
            disputeGameFactory.setImplementation(
                setImplementations[chainId].gameType, IDisputeGame(setImplementations[chainId].implementation)
            );
        }
    }

    /// @notice validates if the implementation is set correctly. Overrrides MultisigTask._validate
    function _validate(uint256 chainId) internal view override {
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(addresses.getAddress("DisputeGameFactoryProxy", chainId));

        if (setImplementations[chainId].l2ChainId != 0) {
            assertEq(
                address(disputeGameFactory.gameImpls(setImplementations[chainId].gameType)),
                setImplementations[chainId].implementation,
                "implementation not set"
            );
        }
    }
}
