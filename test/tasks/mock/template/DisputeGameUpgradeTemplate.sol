// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {IDisputeGameFactory, IDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title DisputeGameUpgradeTemplate
/// @notice Template contract for upgrading dispute game implementations
contract DisputeGameUpgradeTemplate is L2TaskBase {
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
        super._templateSetup(taskConfigFilePath);
        SetImplementation[] memory setImplementation =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".implementations"), (SetImplementation[]));

        for (uint256 i = 0; i < setImplementation.length; i++) {
            setImplementations[setImplementation[i].l2ChainId] = setImplementation[i];
        }
    }

    /// @notice Builds the actions for setting dispute game implementations for a specific L2 chain ID
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            IDisputeGameFactory disputeGameFactory =
                IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));

            if (setImplementations[chainId].l2ChainId != 0) {
                disputeGameFactory.setImplementation(
                    setImplementations[chainId].gameType, IDisputeGame(setImplementations[chainId].implementation)
                );
            }
        }
    }

    /// @notice Validates that implementations were set correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            IDisputeGameFactory dgf =
                IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));

            if (setImplementations[chainId].l2ChainId != 0) {
                assertEq(
                    address(dgf.gameImpls(setImplementations[chainId].gameType)),
                    setImplementations[chainId].implementation,
                    "implementation not set"
                );
            }
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
