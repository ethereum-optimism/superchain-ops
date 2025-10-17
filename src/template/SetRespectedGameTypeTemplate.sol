// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {GameType} from "lib/optimism/packages/contracts-bedrock/src/dispute/lib/Types.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title SetRespectedGameTypeTemplate
/// @notice Sets the respected game type in AnchorStateRegistry for a given chain or set of chains.
contract SetRespectedGameTypeTemplate is L2TaskBase {
    using stdToml for string;

    /// @notice Struct representing configuration for the task.
    struct SetRespectedGameTypeTaskConfig {
        uint256 chainId;
        GameType gameType;
    }

    /// @notice Mapping of chain ID to configuration for the task.
    mapping(uint256 => SetRespectedGameTypeTaskConfig) public cfg;

    /// @notice Execute as the Guardian safe (authorized on ASR).
    function safeAddressString() public pure override returns (string memory) {
        return "GuardianSafe";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "AnchorStateRegistryProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SetRespectedGameTypeTaskConfig[] memory configs =
            abi.decode(tomlContent.parseRaw(".gameTypes.configs"), (SetRespectedGameTypeTaskConfig[]));
        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build(address) internal override {
        // Iterate over the chains and set the respected game type.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address asrAddress = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId);

            // Call ASR to set the current respected game type:
            IAnchorStateRegistry(asrAddress).setRespectedGameType(cfg[chainId].gameType);
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        // Iterate over the chains and validate the respected game type.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address asrAddress = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId);
            IAnchorStateRegistry asr = IAnchorStateRegistry(asrAddress);
            assertEq(asr.respectedGameType().raw(), cfg[chainId].gameType.raw());
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal pure override returns (address[] memory) {
        return new address[](0);
    }
}

// Minimal local copy; only what this template needs.
interface IAnchorStateRegistry {
    function respectedGameType() external view returns (GameType);
    function setRespectedGameType(GameType _gameType) external;
}
