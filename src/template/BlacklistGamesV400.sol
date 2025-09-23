// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface IAnchorStateRegistry {
    function blacklistDisputeGame(address _disputeGame) external;
    function isGameBlacklisted(address _disputeGame) external view returns (bool);
}

/// @notice A template contract to blacklist dispute games
/// Supports: op-contracts/v4.0.0
contract BlacklistGamesV400 is L2TaskBase {
    using stdToml for string;

    /// @notice struct representing configuration for the task.
    struct BlacklistGamesTaskConfig {
        uint256 chainId;
        address[] games;
    }

    /// @notice mapping of chain ID to configuration for the task.
    mapping(uint256 => BlacklistGamesTaskConfig) public cfg;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "Guardian";
    }

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "AnchorStateRegistryProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory tomlContent = vm.readFile(_taskConfigFilePath);
        BlacklistGamesTaskConfig[] memory configs =
            abi.decode(tomlContent.parseRaw(".blacklistGames.configs"), (BlacklistGamesTaskConfig[]));

        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            // Get config for this chain
            uint256 chainId = chains[i].chainId;
            BlacklistGamesTaskConfig memory config = cfg[chainId];

            // Get AnchorStateRegistry
            address asrAddr = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId);
            IAnchorStateRegistry asr = IAnchorStateRegistry(asrAddr);

            // Blacklist each game in the list
            for (uint256 j = 0; j < config.games.length; j++) {
                asr.blacklistDisputeGame(config.games[j]);
            }
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            // Get config for this chain
            uint256 chainId = chains[i].chainId;
            BlacklistGamesTaskConfig memory config = cfg[chainId];

            // Get AnchorStateRegistry
            address asrAddr = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId);
            IAnchorStateRegistry asr = IAnchorStateRegistry(asrAddr);

            // Verify the target games are blacklisted
            for (uint256 j = 0; j < config.games.length; j++) {
                assertEq(asr.isGameBlacklisted(config.games[j]), true);
            }
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal pure override returns (address[] memory) {}
}
