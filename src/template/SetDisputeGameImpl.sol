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
/// IMPORTANT: For each chain you wish to update, you MUST provide both FDG and PDG configurations in the TOML file.
///         - If the provided implementation AND gameArgs match the current on-chain values, that game type is skipped.
///         - This allows updating one game type (e.g., PDG proposer rotation) while leaving the other unchanged.
///         - You are REQUIRED to explicitly specify both configurations for each chain, even if you do not intend to change both.
///         - To reset an implementation to the zero address, provide "0x000...0" as the value in the TOML.
///         - Omitting a field is NOT supported and will result in errors and unintended behavior.
contract SetDisputeGameImpl is L2TaskBase {
    using stdToml for string;

    /// @notice Struct representing configuration for the task.
    struct GameImplConfig {
        uint256 chainId;
        uint256 fdgBond;
        bytes fdgGameArgs;
        address fdgImpl;
        uint256 pdgBond;
        bytes pdgGameArgs;
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
            _applyChainConfig(chains[i].chainId);
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
            _validateChain(chains[i].chainId);
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal pure override returns (address[] memory) {}

    function _applyChainConfig(uint256 chainId) internal {
        GameImplConfig storage c = cfg[chainId];
        require(c.chainId != 0, "SetDisputeGameImpl: Config not found for chain");

        IDisputeGameFactory factory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));

        _setFDGImplementation(factory, c, chainId);
        _setPDGImplementation(factory, c, chainId);
        _setInitBonds(factory, c);
    }

    function _setFDGImplementation(IDisputeGameFactory factory, GameImplConfig storage c, uint256 chainId) internal {
        address currentFDG = address(factory.gameImpls(CANNON));
        if (currentFDG == c.fdgImpl && keccak256(factory.gameArgs(CANNON)) == keccak256(c.fdgGameArgs)) {
            return;
        }
        _validateGameArgsFormat(c.fdgGameArgs, chainId, false);
        factory.setImplementation(CANNON, c.fdgImpl, c.fdgGameArgs);
    }

    function _setPDGImplementation(IDisputeGameFactory factory, GameImplConfig storage c, uint256 chainId) internal {
        address currentPDG = address(factory.gameImpls(PERMISSIONED_CANNON));
        if (currentPDG == c.pdgImpl && keccak256(factory.gameArgs(PERMISSIONED_CANNON)) == keccak256(c.pdgGameArgs)) {
            return;
        }
        _validateGameArgsFormat(c.pdgGameArgs, chainId, true);
        factory.setImplementation(PERMISSIONED_CANNON, c.pdgImpl, c.pdgGameArgs);
    }

    function _setInitBonds(IDisputeGameFactory factory, GameImplConfig storage c) internal {
        if (c.fdgBond != 0 && factory.initBonds(CANNON) != c.fdgBond) {
            factory.setInitBond(CANNON, c.fdgBond);
        }
        if (c.pdgBond != 0 && factory.initBonds(PERMISSIONED_CANNON) != c.pdgBond) {
            factory.setInitBond(PERMISSIONED_CANNON, c.pdgBond);
        }
    }

    function _validateChain(uint256 chainId) internal view {
        GameImplConfig storage c = cfg[chainId];
        require(c.chainId != 0, "SetDisputeGameImpl: Config not found for chain");

        IDisputeGameFactory factory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));

        _validateFactoryTargets(factory, c, chainId);
        _validateBasicInvariants(factory, c, chainId);
        _validateFDGDetailed(c);
        _validatePDGDetailed(c);
    }

    function _validateFactoryTargets(IDisputeGameFactory factory, GameImplConfig storage c, uint256 chainId)
        internal
        view
    {
        require(address(factory.gameImpls(CANNON)) == c.fdgImpl, "FDG implementation mismatch");
        require(address(factory.gameImpls(PERMISSIONED_CANNON)) == c.pdgImpl, "PDG implementation mismatch");
        _validateGameArgs(factory, c, chainId);
    }

    function _validateGameArgs(IDisputeGameFactory factory, GameImplConfig storage c, uint256 chainId) internal view {
        _validateGameArgsFormat(c.fdgGameArgs, chainId, false);
        _validateGameArgsFormat(c.pdgGameArgs, chainId, true);
        require(keccak256(factory.gameArgs(CANNON)) == keccak256(c.fdgGameArgs), "FDG game args mismatch");
        require(keccak256(factory.gameArgs(PERMISSIONED_CANNON)) == keccak256(c.pdgGameArgs), "PDG game args mismatch");
    }

    function _validateGameArgsFormat(bytes storage gameArgs, uint256 chainId, bool permissioned) internal view {
        uint256 expectedLen = permissioned ? 164 : 124;
        require(gameArgs.length == expectedLen, "SetDisputeGameImpl: invalid gameArgs length");

        bytes memory args = gameArgs;
        bytes32 prestate;
        uint256 encodedChainId;
        assembly {
            prestate := mload(add(args, 0x20))
            encodedChainId := mload(add(args, 124))
        }
        require(prestate != bytes32(0), "SetDisputeGameImpl: prestate is zero");
        require(encodedChainId == chainId, "SetDisputeGameImpl: gameArgs chainId mismatch");
    }

    function _validateBasicInvariants(IDisputeGameFactory factory, GameImplConfig storage c, uint256 chainId)
        internal
        view
    {
        if (c.fdgImpl != address(0) && c.fdgImpl != c.prevFdgImpl) {
            IFaultDisputeGame newFdg = IFaultDisputeGame(c.fdgImpl);
            require(newFdg.gameType() == CANNON, "FDG: gameType not CANNON");
            require(newFdg.l2ChainId() == chainId, "FDG: l2ChainId mismatch");
            require(factory.initBonds(CANNON) != 0, "FDG: initBonds not set");
        }

        if (c.pdgImpl != address(0) && c.pdgImpl != c.prevPdgImpl) {
            IPermissionedDisputeGame newPdg = IPermissionedDisputeGame(c.pdgImpl);
            require(newPdg.gameType() == PERMISSIONED_CANNON, "PDG: gameType not PERMISSIONED_CANNON");
            require(newPdg.l2ChainId() == chainId, "PDG: l2ChainId mismatch");
            require(factory.initBonds(PERMISSIONED_CANNON) != 0, "PDG: initBonds not set");
        }
    }

    function _validateFDGDetailed(GameImplConfig storage c) internal view {
        if (c.prevFdgImpl == address(0) || c.fdgImpl == address(0) || c.prevFdgImpl == c.fdgImpl) return;

        IFaultDisputeGame prevFdg = IFaultDisputeGame(c.prevFdgImpl);
        IFaultDisputeGame newFdg = IFaultDisputeGame(c.fdgImpl);

        require(prevFdg.maxGameDepth() == newFdg.maxGameDepth(), "FDG: maxGameDepth mismatch");
        require(prevFdg.splitDepth() == newFdg.splitDepth(), "FDG: splitDepth mismatch");
        require(prevFdg.maxClockDuration() == newFdg.maxClockDuration(), "FDG: maxClockDuration mismatch");
        require(prevFdg.clockExtension() == newFdg.clockExtension(), "FDG: clockExtension mismatch");
        require(prevFdg.anchorStateRegistry() == newFdg.anchorStateRegistry(), "FDG: anchorStateRegistry mismatch");
    }

    function _validatePDGDetailed(GameImplConfig storage c) internal view {
        if (c.prevPdgImpl == address(0) || c.pdgImpl == address(0) || c.prevPdgImpl == c.pdgImpl) return;

        IPermissionedDisputeGame prevPdg = IPermissionedDisputeGame(c.prevPdgImpl);
        IPermissionedDisputeGame newPdg = IPermissionedDisputeGame(c.pdgImpl);

        require(prevPdg.maxGameDepth() == newPdg.maxGameDepth(), "PDG: maxGameDepth mismatch");
        require(prevPdg.splitDepth() == newPdg.splitDepth(), "PDG: splitDepth mismatch");
        require(prevPdg.maxClockDuration() == newPdg.maxClockDuration(), "PDG: maxClockDuration mismatch");
        require(prevPdg.clockExtension() == newPdg.clockExtension(), "PDG: clockExtension mismatch");
        require(prevPdg.proposer() == newPdg.proposer(), "PDG: proposer mismatch");
        require(prevPdg.anchorStateRegistry() == newPdg.anchorStateRegistry(), "PDG: anchorStateRegistry mismatch");
        require(prevPdg.challenger() == newPdg.challenger(), "PDG: challenger mismatch");
    }
}

// ----- GAME TYPE CONSTANTS ----- //
uint32 constant CANNON = 0;
uint32 constant PERMISSIONED_CANNON = 1;

/// ----- INTERFACES ----- ///
interface IDisputeGameFactory {
    function gameImpls(uint32 gameType) external view returns (address);
    function setImplementation(uint32 gameType, address impl, bytes memory gameArgs) external;
    function gameArgs(uint32 gameType) external view returns (bytes memory);
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
