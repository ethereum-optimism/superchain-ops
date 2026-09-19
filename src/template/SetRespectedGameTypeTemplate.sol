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
        return "Guardian";
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

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(cfg[chainId].chainId != 0, "SetRespectedGameType: Config not found for chain");
            address asrAddress = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId);
            address guardian = IAnchorStateRegistry(asrAddress).superchainConfig().guardian();
            _requireRootSafe(rootSafe, guardian);
            address registryFactory = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            address asrFactory = address(IAnchorStateRegistry(asrAddress).disputeGameFactory());
            _requireMatchingDisputeGameFactory(asrFactory, registryFactory);
            _requireGameTypeRegistered(IDisputeGameFactory(asrFactory).gameImpls(cfg[chainId].gameType));
        }
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build(address) internal override {
        // Iterate over the chains and set the respected game type.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address asrAddress = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId);
            IAnchorStateRegistry asr = IAnchorStateRegistry(asrAddress);

            // Verify that we're actually making a change to the respected game type
            require(
                asr.respectedGameType().raw() != cfg[chainId].gameType.raw(),
                "SetRespectedGameType: Game type already set to target value"
            );

            // Call ASR to set the current respected game type
            asr.setRespectedGameType(cfg[chainId].gameType);
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

    function _requireGameTypeRegistered(address implementation) internal pure {
        require(implementation != address(0), "SetRespectedGameType: Game implementation is zero address");
    }

    function _requireMatchingDisputeGameFactory(address actual, address expected) internal pure {
        require(actual == expected, "SetRespectedGameType: DisputeGameFactory mismatch");
    }

    function _requireRootSafe(address rootSafe, address guardian) internal pure {
        require(rootSafe == guardian, "SetRespectedGameType: root safe is not Guardian");
    }
}

// Minimal local copy; only what this template needs.
interface IAnchorStateRegistry {
    function disputeGameFactory() external view returns (IDisputeGameFactory);
    function superchainConfig() external view returns (ISuperchainConfigGuardian);
    function respectedGameType() external view returns (GameType);
    function setRespectedGameType(GameType _gameType) external;
}

interface ISuperchainConfigGuardian {
    function guardian() external view returns (address);
}

interface IDisputeGameFactory {
    function gameImpls(GameType gameType) external view returns (address);
}
