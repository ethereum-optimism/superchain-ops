pragma solidity 0.8.15;

import {IDisputeGameFactory, IDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

/// @title DisputeGameUpgradeTemplate
/// @notice Template contract for upgrading dispute game implementations
contract DisputeGameUpgradeTemplate is MultisigTask {
    /// @notice Struct containing configuration for setting a dispute game implementation
    /// @param gameType The type of game to set the implementation for
    /// @param implementation The address of the new implementation
    /// @param l2ChainId The ID of the L2 chain
    struct SetImplementation {
        GameType gameType;
        address implementation;
        uint256 l2ChainId;
    }

    /// @notice Mapping of L2 chain IDs to their respective implementation configurations
    /// @dev Maps L2 chain ID to SetImplementation struct
    mapping(uint256 => SetImplementation) public setImplementations;

    /// @notice Returns the safe address string identifier
    /// @return The string "ProxyAdminOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        SetImplementation[] memory setImplementation =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".implementations"), (SetImplementation[]));

        for (uint256 i = 0; i < setImplementation.length; i++) {
            setImplementations[setImplementation[i].l2ChainId] = setImplementation[i];
        }
    }

    /// @notice Builds the actions for setting dispute game implementations for a specific L2 chain ID
    /// @param chainId The ID of the L2 chain to configure
    function _build(uint256 chainId) internal override {
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(addresses.getAddress("DisputeGameFactoryProxy", chainId));

        if (setImplementations[chainId].l2ChainId != 0) {
            disputeGameFactory.setImplementation(
                setImplementations[chainId].gameType, IDisputeGame(setImplementations[chainId].implementation)
            );
        }
    }

    /// @notice Validates that implementations were set correctly for the specified chain ID
    /// @param chainId The ID of the L2 chain to validate
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
