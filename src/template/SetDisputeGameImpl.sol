// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title SetDisputeGameImpl
/// @notice This template sets the FaultDisputeGame (FDG) and PermissionedDisputeGame (PDG) implementation addresses
///         in the DisputeGameFactory contract for one or more chains, using values specified in a TOML configuration file.
///
/// IMPORTANT: For each chain you wish to update, you MUST provide both FDG and PDG implementation addresses (old and new) in the TOML file.
///         - If the provided address matches the current on-chain implementation, the contract will SKIP updating it.
///         - You are REQUIRED to explicitly specify both addresses for each chain, even if you do not intend to change both.
///         - To reset an implementation to the zero address, provide "0x000...0" as the value in the TOML.
///         - Omitting a field is NOT supported and will result in errors and unintended behavior.
contract SetDisputeGameImpl is L2TaskBase {
    using stdToml for string;

    /// @notice Struct representing configuration for the task.
    struct GameImplConfig {
        uint256 chainId;
        uint256 fdgBond;
        address fdgImpl;
        uint256 pdgBond;
        address pdgImpl;
        address prevFdgImpl;
        address prevPdgImpl;
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
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory toml = vm.readFile(_taskConfigFilePath);

        GameImplConfig[] memory configs = abi.decode(toml.parseRaw(".gameImplConfig"), (GameImplConfig[]));
        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            GameImplConfig memory c = cfg[chainId];

            address dgf = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            IDisputeGameFactory factory = IDisputeGameFactory(dgf);

            // Set FDG (CANNON) implementation if TOML is different from current on-chain
            address currentFDG = address(factory.gameImpls(CANNON));
            if (currentFDG != c.fdgImpl) {
                factory.setImplementation(CANNON, c.fdgImpl);
            }

            // Set PDG (PERMISSIONED_CANNON) implementation if TOML is different from current on-chain
            address currentPDG = address(factory.gameImpls(PERMISSIONED_CANNON));
            if (currentPDG != c.pdgImpl) {
                factory.setImplementation(PERMISSIONED_CANNON, c.pdgImpl);
            }

            // Set FDG bond if not already set or needs update
            if (c.fdgBond != 0 && factory.initBonds(CANNON) != c.fdgBond) {
                factory.setInitBond(CANNON, c.fdgBond);
            }

            // Set PDG bond if not already set or needs update
            if (c.pdgBond != 0 && factory.initBonds(PERMISSIONED_CANNON) != c.pdgBond) {
                factory.setInitBond(PERMISSIONED_CANNON, c.pdgBond);
            }
        }
    }

    /// @notice Validates that the DisputeGameFactory and game implementation invariants are preserved after the upgrade.
    ///         This includes checking that all implementations match the TOML config, and that only allowed fields
    ///         differ between old and new implementations (mainly for prestate or prestate + VM updates).
    ///         Always checks that any new FDG/PDG impl is of the correct type and l2ChainId, regardless of scenario.
    ///         Detailed logic checks are performed only when updating between two nonzero implementations,
    ///         i.e., not when adding a brand new implementation or resetting to the zero address.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            GameImplConfig memory c = cfg[chainId];
            if (c.chainId == 0) continue; // Skip chains without configurations

            address dgf = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            IDisputeGameFactory factory = IDisputeGameFactory(dgf);

            // Always check that DisputeGameFactory points to the expected new implementations from TOML config file
            require(address(factory.gameImpls(CANNON)) == c.fdgImpl, "FDG implementation mismatch");
            require(address(factory.gameImpls(PERMISSIONED_CANNON)) == c.pdgImpl, "PDG implementation mismatch");

            // Always check basic invariants on any nonzero FDG new implementation
            if (c.fdgImpl != address(0) && c.fdgImpl != c.prevFdgImpl) {
                IFaultDisputeGame newFdg = IFaultDisputeGame(c.fdgImpl);
                require(newFdg.gameType() == CANNON, "FDG: gameType not CANNON");
                require(newFdg.l2ChainId() == chainId, "FDG: l2ChainId mismatch");
                require(factory.initBonds(CANNON) != 0, "FDG: initBonds not set");
            }

            // Always check basic invariants on any nonzero PDG new implementation
            if (c.pdgImpl != address(0) && c.pdgImpl != c.prevPdgImpl) {
                IPermissionedDisputeGame newPdg = IPermissionedDisputeGame(c.pdgImpl);
                require(newPdg.gameType() == PERMISSIONED_CANNON, "PDG: gameType not PERMISSIONED_CANNON");
                require(newPdg.l2ChainId() == chainId, "PDG: l2ChainId mismatch");
                require(factory.initBonds(PERMISSIONED_CANNON) != 0, "PDG: initBonds not set");
            }

            // -- FDG detailed check (only for impl->impl upgrade, not 0->impl or impl->0) --
            address prevFdgAddr = c.prevFdgImpl;
            address newFdgAddr = c.fdgImpl;
            if (prevFdgAddr != address(0) && newFdgAddr != address(0) && prevFdgAddr != newFdgAddr) {
                IFaultDisputeGame prevFdg = IFaultDisputeGame(prevFdgAddr);
                IFaultDisputeGame newFdg = IFaultDisputeGame(newFdgAddr);

                // Check if prestate or vm changed
                bool prestateChanged = prevFdg.absolutePrestate() != newFdg.absolutePrestate();
                bool vmChanged = address(prevFdg.vm()) != address(newFdg.vm());

                // All other fields must match
                bool othersMatch = prevFdg.maxGameDepth() == newFdg.maxGameDepth()
                    && prevFdg.splitDepth() == newFdg.splitDepth()
                    && prevFdg.maxClockDuration() == newFdg.maxClockDuration()
                    && prevFdg.clockExtension() == newFdg.clockExtension()
                    && prevFdg.anchorStateRegistry() == newFdg.anchorStateRegistry();

                // Acceptable: prestate-only update or prestate+vm update
                if (prestateChanged || vmChanged) {
                    require(othersMatch, "FDG: Core fields changed unexpectedly (allowed prestate/vm update)");
                } else {
                    // No prestate/vm changed but allow only if all fields match
                    require(othersMatch, "FDG: Core fields mismatch");
                }
            }

            // -- PDG detailed check (only for impl->impl upgrade, not 0->impl or impl->0) --
            address prevPdgAddr = c.prevPdgImpl;
            address newPdgAddr = c.pdgImpl;
            if (prevPdgAddr != address(0) && newPdgAddr != address(0) && prevPdgAddr != newPdgAddr) {
                IPermissionedDisputeGame prevPdg = IPermissionedDisputeGame(prevPdgAddr);
                IPermissionedDisputeGame newPdg = IPermissionedDisputeGame(newPdgAddr);

                // Check if prestate or vm changed
                bool prestateChanged = prevPdg.absolutePrestate() != newPdg.absolutePrestate();
                bool vmChanged = address(prevPdg.vm()) != address(newPdg.vm());

                // All other fields must match
                bool othersMatch = prevPdg.maxGameDepth() == newPdg.maxGameDepth()
                    && prevPdg.splitDepth() == newPdg.splitDepth()
                    && prevPdg.maxClockDuration() == newPdg.maxClockDuration()
                    && prevPdg.clockExtension() == newPdg.clockExtension() && prevPdg.proposer() == newPdg.proposer()
                    && prevPdg.anchorStateRegistry() == newPdg.anchorStateRegistry()
                    && prevPdg.challenger() == newPdg.challenger();

                // Acceptable: prestate-only update or prestate+vm update
                if (prestateChanged || vmChanged) {
                    require(othersMatch, "PDG: Core fields changed unexpectedly (allowed prestate/vm update)");
                } else {
                    // No prestate/vm changed but allow only if all fields match
                    require(othersMatch, "PDG: Core fields mismatch");
                }
            }
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal pure override returns (address[] memory) {}
}

// ----- GAME TYPE CONSTANTS ----- //
uint32 constant CANNON = 0;
uint32 constant PERMISSIONED_CANNON = 1;

/// ----- INTERFACES ----- ///
interface IDisputeGameFactory {
    function gameImpls(uint32 gameType) external view returns (address);
    function setImplementation(uint32 gameType, address impl) external;
    function initBonds(uint32 gameType) external view returns (uint256);
    function setInitBond(uint32 gameType, uint256 amount) external;
}

interface IFaultDisputeGame {
    function gameType() external view returns (uint32);
    function l2ChainId() external view returns (uint256);
    function version() external view returns (string memory);
    function anchorStateRegistry() external view returns (address);
    function maxGameDepth() external view returns (uint256);
    function splitDepth() external view returns (uint256);
    function maxClockDuration() external view returns (uint64);
    function clockExtension() external view returns (uint64);
    function vm() external view returns (address);
    function absolutePrestate() external view returns (bytes32);
}

interface IPermissionedDisputeGame {
    function gameType() external view returns (uint32);
    function l2ChainId() external view returns (uint256);
    function version() external view returns (string memory);
    function anchorStateRegistry() external view returns (address);
    function maxGameDepth() external view returns (uint256);
    function splitDepth() external view returns (uint256);
    function maxClockDuration() external view returns (uint64);
    function clockExtension() external view returns (uint64);
    function vm() external view returns (address);
    function absolutePrestate() external view returns (bytes32);
    function proposer() external view returns (address);
    function challenger() external view returns (address);
}
