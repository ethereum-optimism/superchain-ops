pragma solidity 0.8.15;

import {SystemConfig} from "src/fps/example/ISystemConfig.sol";
import {MultisigProposal} from "src/fps/proposal/MultisigProposal.sol";
import {NetworkTranslator} from "src/fps/utils/NetworkTranslator.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";
import {BASE_CHAIN_ID, OP_CHAIN_ID, ADDRESSES_PATH} from "src/fps/utils/Constants.sol";
import {IDisputeGameFactory} from "src/fps/example/IDisputeGameFactory.sol";

import "forge-std/console.sol";

contract DisputeGameUpgradeTemplate is MultisigProposal {
    /// @notice struct to store information about an implementation to be set for a specific l2 chain id
    struct SetImplementation {
        uint32 gameType;
        string implementation;
        uint256 l2ChainId;
    }

    /// @notice maps a l2 chain id to a SetImplementation struct
    mapping(uint256 => SetImplementation) public setImplementations;

    /// @notice Runs the proposal with the given task and network configuration file paths. Sets the address registry, initializes the proposal and processes the proposal.
    /// @param taskConfigFilePath The path to the task configuration file.
    /// @param networkConfigFilePath The path to the network configuration file.
    function run(string memory taskConfigFilePath, string memory networkConfigFilePath) public {
        Addresses _addresses = new Addresses(ADDRESSES_PATH, networkConfigFilePath);

        _init(taskConfigFilePath, networkConfigFilePath, _addresses);

        SetImplementation[] memory setImplementation =
            abi.decode(vm.parseToml(vm.readFile(networkConfigFilePath), ".implementations"), (SetImplementation[]));

        for (uint256 i = 0; i < setImplementation.length; i++) {
            setImplementations[setImplementation[i].l2ChainId] = setImplementation[i];
        }

        processProposal();
    }

    /// @notice builds setImplementation action for the given chainId. Overrrides MultisigProposal._build
    function _build(uint256 chainId) internal override {
        /// view only, filtered out by Proposal.sol
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(addresses.getAddress("DisputeGameFactoryProxy", chainId));

        if (setImplementations[chainId].l2ChainId != 0) {
            disputeGameFactory.setImplementation(
                setImplementations[chainId].gameType,
                addresses.getAddress(setImplementations[chainId].implementation, chainId)
            );
        }
    }

    /// @notice validates if the implementation is set correctly. Overrrides MultisigProposal._validate
    function _validate(uint256 chainId) internal view override {
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(addresses.getAddress("DisputeGameFactoryProxy", chainId));

        if (setImplementations[chainId].l2ChainId != 0) {
            assertEq(
                disputeGameFactory.gameImpls(setImplementations[chainId].gameType),
                addresses.getAddress(setImplementations[chainId].implementation, chainId),
                "implementation not set"
            );
        }
    }
}
