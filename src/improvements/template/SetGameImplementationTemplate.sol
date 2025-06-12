// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

import {DisputeGameFactory} from "lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol";
import {GameTypes} from "lib/optimism/packages/contracts-bedrock/src/dispute/lib/Types.sol";

import {IFaultDisputeGame} from "lib/optimism/packages/contracts-bedrock/interfaces/dispute/IFaultDisputeGame.sol";
import {IPermissionedDisputeGame} from "lib/optimism/packages/contracts-bedrock/interfaces/dispute/IPermissionedDisputeGame.sol";

/// @title SetGameImplementationTemplate
/// @notice This template is used to set the implementation of FDG and PDF in the DisputeGameFactory contract
///         for a given chain or set of chains.
contract SetGameImplementationsTemplate is L2TaskBase {
    using stdToml for string;

    /// @notice Struct representing configuration for the task.
    struct GameImplConfig {
        uint256 chainId;
        address fdgImpl;
        address pdgImpl;
    }

    /// @notice Mapping of chain ID to configuration for the task.
    mapping(uint256 => GameImplConfig) public cfg;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "FoundationOperationsSafe";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory toml = vm.readFile(taskConfigFilePath);
        GameImplConfig[] memory configs = 
            abi.decode(toml.parseRaw(".gameImpls.configs"), (GameImplConfig[]));
        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        
        // Iterate over the chains and set the implementation of FDG and/or PDG according to what is specified in the TOML.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            
            // Skip chains that don't have a configuration
            if (cfg[chainId].chainId == 0) continue;
            
            GameImplConfig memory c = cfg[chainId];

            address dgf = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);

            if (c.fdgImpl != address(0)) {
                DisputeGameFactory(dgf).setImplementation(GameTypes.CANNON, IFaultDisputeGame(c.fdgImpl));
            }
            if (c.pdgImpl != address(0)) {
                DisputeGameFactory(dgf).setImplementation(GameTypes.PERMISSIONED_CANNON, IPermissionedDisputeGame(c.pdgImpl));
            }
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        // Iterate over the chains and validate the respected game type.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            GameImplConfig memory c = cfg[chainId];

            address dgf = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            DisputeGameFactory factory = DisputeGameFactory(dgf);

            if (c.fdgImpl != address(0)) {
                assertEq(address(factory.gameImpls(GameTypes.CANNON)), c.fdgImpl);
            }
            if (c.pdgImpl != address(0)) {
                assertEq(address(factory.gameImpls(GameTypes.PERMISSIONED_CANNON)), c.pdgImpl);
            }
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory codeExceptions = new address[](0);
        return codeExceptions;
    }
}
