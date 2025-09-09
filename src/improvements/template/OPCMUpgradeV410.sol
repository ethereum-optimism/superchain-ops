// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    IOPContractsManager,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {OPCMTaskBase} from "src/improvements/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice OPCM V4.1.0 upgrade template.
/// @dev This template is used to upgrade OPCMs from V3.0.0 or v4.0.0 to V4.1.0.
/// @dev For any OP Chain being upgraded by this template, it is expected that it's superchainConfig
///      is already upgraded since this OPCM does not also upgrade the SuperchainConfig contract like past OPCMs.
/// @dev To upgrade the SuperchainConfig contract, use the OPCMUpgradeSuperchainConfigV410 template.
/// Supports: op-contracts/v4.1.0
contract OPCMUpgradeV410 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    IStandardValidatorV410 public STANDARD_VALIDATOR_V410;

    /// @notice Struct to store inputs data for each L2 chain.
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
        string expectedValidationErrors;
    }

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](9);
        storageWrites[0] = "ProxyAdminOwner";
        storageWrites[1] = "DisputeGameFactoryProxy";
        storageWrites[2] = "SystemConfigProxy";
        storageWrites[3] = "OptimismPortalProxy";
        storageWrites[4] = "AddressManager";
        storageWrites[5] = "L1CrossDomainMessengerProxy";
        storageWrites[6] = "L1StandardBridgeProxy";
        storageWrites[7] = "L1ERC721BridgeProxy";
        storageWrites[8] = "AnchorStateRegistryProxy";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory tomlContent = vm.readFile(_taskConfigFilePath);

        // OPCMUpgrade struct is used to store the absolutePrestate and expectedValidationErrors for each l2 chain.
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        address OPCM = tomlContent.readAddress(".addresses.OPCM");
        OPCM_TARGETS.push(OPCM);
        require(IOPContractsManager(OPCM).version().eq("3.2.0"), "Incorrect OPCM");
        vm.label(OPCM, "OPCM");

        STANDARD_VALIDATOR_V410 = IStandardValidatorV410(tomlContent.readAddress(".addresses.StandardValidatorV410"));
        require(
            address(STANDARD_VALIDATOR_V410).code.length > 0, "Incorrect StandardValidatorV410 - no code at address"
        );
        vm.label(address(STANDARD_VALIDATOR_V410), "StandardValidatorV410");
    }

    /// @notice Builds the actions for executing the operations.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        IOPContractsManager.OpChainConfig[] memory opChainConfigs =
            new IOPContractsManager.OpChainConfig[](chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chainId)),
                absolutePrestate: upgrades[chainId].absolutePrestate
            });
        }

        (bool success,) = OPCM_TARGETS[0].delegatecall(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(success, "OPCMUpgradeV410: Delegatecall failed in _build.");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            bytes32 expAbsolutePrestate = Claim.unwrap(upgrades[chainId].absolutePrestate);
            string memory expErrors = upgrades[chainId].expectedValidationErrors;
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV410.InputV410 memory input = IStandardValidatorV410.InputV410({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: expAbsolutePrestate,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V410.validate({_input: input, _allowFailure: true});

            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface IStandardValidatorV410 {
    struct InputV410 {
        address proxyAdmin;
        address sysCfg;
        bytes32 absolutePrestate;
        uint256 l2ChainID;
    }

    function validate(InputV410 memory _input, bool _allowFailure) external view returns (string memory);
}
