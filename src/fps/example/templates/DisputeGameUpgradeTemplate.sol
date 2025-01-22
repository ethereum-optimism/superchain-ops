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
        string implementation;
        uint256 l2ChainId;
    }

    /// @notice maps a l2 chain id to a SetImplementation struct
    mapping(uint256 => SetImplementation) public setImplementations;

    /// @notice Runs the proposal with the given task and network configuration file paths. Sets the address registry, initializes the proposal and processes the proposal.
    /// @param taskConfigFilePath The path to the task configuration file.
    /// @param networkConfigFilePath The path to the network configuration file.
    function run(string memory taskConfigFilePath, string memory networkConfigFilePath) public {
        Addresses _addresses = new Addresses(networkConfigFilePath);

        _init(taskConfigFilePath, networkConfigFilePath, _addresses);

        SetImplementation[] memory setImplementation =
            abi.decode(vm.parseToml(vm.readFile(networkConfigFilePath), ".implementations"), (SetImplementation[]));

        for (uint256 i = 0; i < setImplementation.length; i++) {
            setImplementations[setImplementation[i].l2ChainId] = setImplementation[i];
        }

        _processTask();
    }

    /// @notice builds setImplementation action for the given chainId. Overrrides MultisigTask._build
    function _build(uint256 chainId) internal override {
        /// view only, filtered out by Proposal.sol
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(addresses.getAddress("DisputeGameFactoryProxy", chainId));

        if (setImplementations[chainId].l2ChainId != 0) {
            disputeGameFactory.setImplementation(
                setImplementations[chainId].gameType,
                IDisputeGame(addresses.getAddress(setImplementations[chainId].implementation, chainId))
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
                addresses.getAddress(setImplementations[chainId].implementation, chainId),
                "implementation not set"
            );
        }
    }
}
