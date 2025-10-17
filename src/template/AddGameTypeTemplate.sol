// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

import {GameType, Claim, Duration} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {
    IOPContractsManager,
    IDisputeGameFactory,
    IFaultDisputeGame,
    IBigStepper,
    IProxyAdmin,
    IDelayedWETH,
    ISystemConfig
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";

/// @title AddGameTypeTemplate
/// @notice This template is used to add a game type to the DisputeGameFactory contract.
contract AddGameTypeTemplate is OPCMTaskBase {
    using stdToml for string;

    /// @notice Struct that extends the original AddGameInput struct and includes the chain id.
    ///         Notably the fields here are also in alphabetical order, this is required because of
    ///         the way that Foundry parses TOML data. This MUST be kept in alphabetical order. If
    ///         you are adding a new field, you MUST make sure it's in order. Seriously.
    struct AddGameInputWithChainId {
        uint256 chainId;
        IDelayedWETH delayedWETH;
        Claim disputeAbsolutePrestate;
        Duration disputeClockExtension;
        GameType disputeGameType;
        Duration disputeMaxClockDuration;
        uint256 disputeMaxGameDepth;
        uint256 disputeSplitDepth;
        uint256 initialBond;
        bool permissioned;
        IProxyAdmin proxyAdmin;
        string saltMixer;
        ISystemConfig systemConfig;
        IBigStepper vm;
    }

    /// @notice Mapping of chain ID to configuration for the task.
    mapping(uint256 => AddGameInputWithChainId) private cfg;

    /// @notice Address of the OPCM contract.
    address private OPCM;

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // Load configuration.
        AddGameInputWithChainId[] memory configs =
            abi.decode(tomlContent.parseRaw(".configs"), (AddGameInputWithChainId[]));
        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }

        // Load OPCM address.
        OPCM = tomlContent.readAddress(".addresses.OPCM");
        require(OPCM != address(0), "OPCM not set");
        vm.label(OPCM, "OPCM");

        // Set OPCM as the target for delegatecalls.
        OPCM_TARGETS = new address[](1);
        OPCM_TARGETS[0] = OPCM;
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build(address) internal override {
        // Iterate over the chains pull out the configs.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        IOPContractsManager.AddGameInput[] memory configs = new IOPContractsManager.AddGameInput[](chains.length);
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            configs[i] = _toAddGameInput(cfg[chainId]);
        }

        // Delegatecall the OPCM.addGameType() function.
        (bool success,) = OPCM.delegatecall(abi.encodeCall(IOPContractsManager.addGameType, (configs)));
        require(success, "AddGameType: failed to add game type");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        // Iterate over the chains and validate the respected game type.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address factoryAddress = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            IDisputeGameFactory factory = IDisputeGameFactory(factoryAddress);
            IFaultDisputeGame game = IFaultDisputeGame(address(factory.gameImpls(cfg[chainId].disputeGameType)));

            // Assert that everything is as expected.
            assertEq(address(game.weth()), address(cfg[chainId].delayedWETH));
            assertEq(game.gameType().raw(), cfg[chainId].disputeGameType.raw());
            assertEq(game.absolutePrestate().raw(), cfg[chainId].disputeAbsolutePrestate.raw());
            assertEq(game.maxGameDepth(), cfg[chainId].disputeMaxGameDepth);
            assertEq(game.splitDepth(), cfg[chainId].disputeSplitDepth);
            assertEq(game.clockExtension().raw(), cfg[chainId].disputeClockExtension.raw());
            assertEq(game.maxClockDuration().raw(), cfg[chainId].disputeMaxClockDuration.raw());

            // Assert that the bond is set correctly.
            assertEq(factory.initBonds(cfg[chainId].disputeGameType), cfg[chainId].initialBond);
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}

    /// @notice Converts the AddGameInputWithChainId struct to the AddGameInput struct.
    function _toAddGameInput(AddGameInputWithChainId memory _input)
        internal
        pure
        returns (IOPContractsManager.AddGameInput memory)
    {
        return IOPContractsManager.AddGameInput({
            saltMixer: _input.saltMixer,
            systemConfig: _input.systemConfig,
            proxyAdmin: _input.proxyAdmin,
            delayedWETH: _input.delayedWETH,
            disputeGameType: _input.disputeGameType,
            disputeAbsolutePrestate: _input.disputeAbsolutePrestate,
            disputeMaxGameDepth: _input.disputeMaxGameDepth,
            disputeSplitDepth: _input.disputeSplitDepth,
            disputeClockExtension: _input.disputeClockExtension,
            disputeMaxClockDuration: _input.disputeMaxClockDuration,
            initialBond: _input.initialBond,
            vm: _input.vm,
            permissioned: _input.permissioned
        });
    }
}
