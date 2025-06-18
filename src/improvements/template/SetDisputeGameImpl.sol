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
import {IPermissionedDisputeGame} from
    "lib/optimism/packages/contracts-bedrock/interfaces/dispute/IPermissionedDisputeGame.sol";

/// @title SetDisputeGameImpl
/// @notice This template sets the FaultDisputeGame (FDG) and PermissionedDisputeGame (PDG) implementation addresses
///         in the DisputeGameFactory contract for one or more chains, using values specified in a TOML configuration file.
///
/// IMPORTANT: For each chain you wish to update, you MUST provide both FDG and PDG implementation addresses in the TOML file.
///         - If the provided address matches the current on-chain implementation, the contract will SKIP updating it.
///         - You are REQUIRED to explicitly specify both addresses for each chain, even if you do not intend to change both.
///         - To reset an implementation to the zero address, provide "0x000...0" as the value in the TOML.
///         - Omitting a field is NOT supported and will result in errors and unintended behavior.
contract SetDisputeGameImpl is L2TaskBase {
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
        return "ProxyAdminOwner";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory toml = vm.readFile(taskConfigFilePath);

        GameImplConfig[] memory configs = abi.decode(toml.parseRaw(".gameImpls.configs"), (GameImplConfig[]));
        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            GameImplConfig memory c = cfg[chainId];

            address dgf = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            DisputeGameFactory factory = DisputeGameFactory(dgf);

            // Set FDG (CANNON) implementation if TOML is different from current on-chain
            address currentFDG = address(factory.gameImpls(GameTypes.CANNON));
            if (currentFDG != c.fdgImpl) {
                factory.setImplementation(GameTypes.CANNON, IFaultDisputeGame(c.fdgImpl));
            }

            // Set PDG (PERMISSIONED_CANNON) implementation if TOML is different from current on-chain
            address currentPDG = address(factory.gameImpls(GameTypes.PERMISSIONED_CANNON));
            if (currentPDG != c.pdgImpl) {
                factory.setImplementation(GameTypes.PERMISSIONED_CANNON, IPermissionedDisputeGame(c.pdgImpl));
            }
        }
    }

    /// @notice Validates that the DisputeGameFactory and game implementation invariants are preserved after the upgrade.
    ///         This includes checking that all implementations match the TOML config, and that only allowed fields
    ///         differ between old and new implementations (mainly for prestate or prestate + VM updates).
    ///         Always checks that any new FDG/PDG impl is of the correct type and l2ChainId, regardless of scenario.
    ///         Detailed logic checks are performed only when updating between two nonzero implementations,
    ///         i.e., not when adding a brand new implementation or resetting to the zero address.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            GameImplConfig memory c = cfg[chainId];

            address dgf = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            DisputeGameFactory factory = DisputeGameFactory(dgf);

            // Always check that DisputeGameFactory points to the expected new implementations from TOML config file
            assertEq(address(factory.gameImpls(GameTypes.CANNON)), c.fdgImpl, "FDG implementation mismatch");
            assertEq(address(factory.gameImpls(GameTypes.PERMISSIONED_CANNON)), c.pdgImpl, "PDG implementation mismatch");

            // Always check basic invariants on any nonzero FDG new implementation
            if (c.fdgImpl != address(0)) {
                IFaultDisputeGame newFdg = IFaultDisputeGame(c.fdgImpl);
                require(newFdg.gameType().raw() == GameTypes.CANNON.raw(), "FDG: gameType not CANNON");
                require(newFdg.l2ChainId() == chainId, "FDG: l2ChainId mismatch");
            }

            // Always check basic invariants on any nonzero PDG new implementation
            if (c.pdgImpl != address(0)) {
                IPermissionedDisputeGame newPdg = IPermissionedDisputeGame(c.pdgImpl);
                require(newPdg.gameType().raw() == GameTypes.PERMISSIONED_CANNON.raw(), "PDG: gameType not PERMISSIONED_CANNON");
                require(newPdg.l2ChainId() == chainId, "PDG: l2ChainId mismatch");
            }

            // -- FDG detailed check (only for impl->impl upgrade, not 0->impl or impl->0) --
            address prevFdgAddr = address(factory.gameImpls(GameTypes.CANNON));
            address newFdgAddr = c.fdgImpl;
            if (prevFdgAddr != address(0) && newFdgAddr != address(0) && prevFdgAddr != newFdgAddr) {
                IFaultDisputeGame prevFdg = IFaultDisputeGame(prevFdgAddr);
                IFaultDisputeGame newFdg = IFaultDisputeGame(newFdgAddr);

                // Check what changed
                bool prestateChanged = prevFdg.anchorStateRegistry() != newFdg.anchorStateRegistry();
                bool vmChanged = address(prevFdg.vm()) != address(newFdg.vm());

                // All other fields (except prestate/vm) must match
                bool othersMatch =
                    keccak256(bytes(prevFdg.version())) == keccak256(bytes(newFdg.version())) &&
                    prevFdg.maxGameDepth() == newFdg.maxGameDepth() &&
                    prevFdg.splitDepth() == newFdg.splitDepth() &&
                    prevFdg.maxClockDuration().raw() == newFdg.maxClockDuration().raw() &&
                    prevFdg.clockExtension().raw() == newFdg.clockExtension().raw();

                // Acceptable: prestate-only update or prestate+vm update
                if (prestateChanged && !vmChanged) {
                    require(othersMatch, "FDG: Core fields changed unexpectedly (prestate update)");
                } else if (prestateChanged && vmChanged) {
                    require(othersMatch, "FDG: Core fields changed unexpectedly (VM upgrade)");
                } else {
                    revert("FDG: Invalid update pattern (unexpected fields changed)");
                }
            }

            // -- PDG detailed check (only for impl->impl upgrade, not 0->impl or impl->0) --
            address prevPdgAddr = address(factory.gameImpls(GameTypes.PERMISSIONED_CANNON));
            address newPdgAddr = c.pdgImpl;
            if (prevPdgAddr != address(0) && newPdgAddr != address(0) && prevPdgAddr != newPdgAddr) {
                IPermissionedDisputeGame prevPdg = IPermissionedDisputeGame(prevPdgAddr);
                IPermissionedDisputeGame newPdg = IPermissionedDisputeGame(newPdgAddr);

                // Check what changed
                bool prestateChanged = prevPdg.anchorStateRegistry() != newPdg.anchorStateRegistry();
                bool vmChanged = address(prevPdg.vm()) != address(newPdg.vm());

                // All other fields (except prestate/vm) must match
                bool othersMatch =
                    keccak256(bytes(prevPdg.version())) == keccak256(bytes(newPdg.version())) &&
                    prevPdg.maxGameDepth() == newPdg.maxGameDepth() &&
                    prevPdg.splitDepth() == newPdg.splitDepth() &&
                    prevPdg.maxClockDuration().raw() == newPdg.maxClockDuration().raw() &&
                    prevPdg.clockExtension().raw() == newPdg.clockExtension().raw() &&
                    prevPdg.proposer() == newPdg.proposer() &&
                    prevPdg.challenger() == newPdg.challenger();

                // Acceptable: prestate-only update or prestate+vm update
                // Note: proposer/challenger are not expected to change, but we check them for completeness
                //       since they are core fields in PDG.
                if (prestateChanged && !vmChanged) {
                    require(othersMatch, "PDG: Core fields changed unexpectedly (prestate update)");
                } else if (prestateChanged && vmChanged) {
                    require(othersMatch, "PDG: Core fields changed unexpectedly (VM upgrade)");
                } else {
                    revert("PDG: Invalid update pattern (unexpected fields changed)");
                }
            }
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory codeExceptions = new address[](1);
        codeExceptions[0] = address(0);
        return codeExceptions;
    }
}
