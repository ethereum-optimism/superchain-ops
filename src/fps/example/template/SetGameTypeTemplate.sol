pragma solidity 0.8.15;

import {
    DeputyGuardianModule, IOptimismPortal2, GameType
} from "@eth-optimism-bedrock/src/safe/DeputyGuardianModule.sol";
import {LibGameType} from "@eth-optimism-bedrock/src/dispute/lib/LibUDT.sol";

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

/// @title SetGameTypeTemplate
/// @notice Template contract for setting game types in the Optimism system
contract SetGameTypeTemplate is MultisigTask {
    using LibGameType for GameType;

    /// @notice Struct containing configuration for setting a respected game type
    /// @param deputyGuardian Address of the deputy guardian
    /// @param gameType The game type to be set
    /// @param l2ChainId The ID of the L2 chain
    /// @param portal The portal identifier string
    struct SetRespectedGameType {
        address deputyGuardian;
        GameType gameType;
        uint256 l2ChainId;
        string portal;
    }

    /// @notice Mapping of L2 chain IDs to their respective game type configurations
    /// @dev Maps L2 chain ID to SetRespectedGameType struct
    mapping(uint256 => SetRespectedGameType) public setRespectedGameTypes;

    /// @notice Returns the safe address string identifier
    /// @return The string "Challenger"
    function safeAddressString() public pure override returns (string memory) {
        return "Challenger";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "OptimismPortalProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with game type configurations from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        SetRespectedGameType[] memory setRespectedGameType =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".respectedGameTypes"), (SetRespectedGameType[]));

        for (uint256 i = 0; i < setRespectedGameType.length; i++) {
            setRespectedGameTypes[setRespectedGameType[i].l2ChainId] = setRespectedGameType[i];
        }
    }

    /// @notice Builds the actions for setting game types for a specific L2 chain ID
    /// @param chainId The ID of the L2 chain to configure
    function _build(uint256 chainId) internal override {
        if (setRespectedGameTypes[chainId].l2ChainId != 0) {
            DeputyGuardianModule(setRespectedGameTypes[chainId].deputyGuardian).setRespectedGameType(
                IOptimismPortal2(payable(addresses.getAddress(setRespectedGameTypes[chainId].portal, chainId))),
                setRespectedGameTypes[chainId].gameType
            );
        }
    }

    /// @notice Validates that game types were set correctly for the specified chain ID
    /// @param chainId The ID of the L2 chain to validate
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
