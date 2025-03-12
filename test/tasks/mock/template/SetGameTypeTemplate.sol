// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    DeputyGuardianModule, IOptimismPortal2, GameType
} from "@eth-optimism-bedrock/src/safe/DeputyGuardianModule.sol";
import {LibGameType} from "@eth-optimism-bedrock/src/dispute/lib/LibUDT.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {L2TaskBase} from "src/improvements/tasks/MultisigTask.sol";

/// @title SetGameTypeTemplate
/// @notice Template contract for setting game types in the Optimism system
contract SetGameTypeTemplate is L2TaskBase {
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
        super._templateSetup(taskConfigFilePath);
        SetRespectedGameType[] memory setRespectedGameType =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".respectedGameTypes"), (SetRespectedGameType[]));

        for (uint256 i = 0; i < setRespectedGameType.length; i++) {
            setRespectedGameTypes[setRespectedGameType[i].l2ChainId] = setRespectedGameType[i];
        }
    }

    /// @notice Builds the actions for setting respected game types.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            if (setRespectedGameTypes[chainId].l2ChainId != 0) {
                DeputyGuardianModule dgm = DeputyGuardianModule(setRespectedGameTypes[chainId].deputyGuardian);
                address portal = superchainAddrRegistry.getAddress(setRespectedGameTypes[chainId].portal, chainId);
                dgm.setRespectedGameType(IOptimismPortal2(payable(portal)), setRespectedGameTypes[chainId].gameType);
            }
        }
    }

    /// @notice Validates that game types were set correctly.abi
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            IOptimismPortal2 portal =
                IOptimismPortal2(payable(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId)));
            if (setRespectedGameTypes[chainId].l2ChainId != 0) {
                uint256 currentGameType = portal.respectedGameType().raw();
                assertEq(currentGameType, setRespectedGameTypes[chainId].gameType.raw(), "gameType not set");
            }
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
