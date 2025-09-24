// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    IOPContractsManager,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {IStandardValidatorV200} from "@eth-optimism-bedrock/interfaces/L1/IStandardValidator.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice Use this template for chains that are on U12 and need to be upgraded to U16a (inclusive).
///         The template applies each required OPCM upgrade step (U13, U14, U15, U16a) in sequence.
/// Supports: op-contracts/v1.8.0
contract OPCMUpgradeV220toV410 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice Validators
    IStandardValidatorV200 public STANDARD_VALIDATOR_V200;
    IStandardValidatorV300 public STANDARD_VALIDATOR_V300;
    IStandardValidatorV410 public STANDARD_VALIDATOR_V410;

    /// @notice Address of the OPCM for U13, U14, U15 and U16a.
    address public OPCM_V220;
    address public OPCM_V300;
    address public OPCM_V410;

    /// @notice Prestates for the OPCM upgrades.
    bytes32 public OPCM_V220_PRESTATE;
    bytes32 public OPCM_V300_PRESTATE;
    bytes32 public OPCM_V300_UPDATE_PRESTATE;
    bytes32 public OPCM_V410_PRESTATE;

    /// @notice Struct to store inputs for OPCM.upgrade() function per L2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
        string expectedErrorsV220; // Expected Validation Errors for U13
        string expectedErrorsV300; // Expected Validation Errors for U14/U15
        string expectedErrorsV410; // Expected Validation Errors for U16a
    }

    /// @notice Mapping from chain ID to upgrade parameters
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice Returns the storage write permissions
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](16);
        storageWrites[0] = "ProxyAdminOwner";
        storageWrites[1] = "OPCMUpgradeV220";
        storageWrites[2] = "SuperchainConfig";
        storageWrites[3] = "DisputeGameFactoryProxy";
        storageWrites[4] = "SystemConfigProxy";
        storageWrites[5] = "OptimismPortalProxy";
        storageWrites[6] = "AddressManager";
        storageWrites[7] = "L1CrossDomainMessengerProxy";
        storageWrites[8] = "L1StandardBridgeProxy";
        storageWrites[9] = "L1ERC721BridgeProxy";
        storageWrites[10] = "ProtocolVersions";
        storageWrites[11] = "OptimismMintableERC20FactoryProxy";
        storageWrites[12] = "PermissionedWETH";
        storageWrites[13] = "PermissionlessWETH";
        storageWrites[14] = "OPCMUpgradeV300";
        storageWrites[15] = "OPCMUpgradeV410";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {
        string[] memory balanceChanges = new string[](1);
        balanceChanges[0] = "OptimismPortalProxy";
        // Not adding EthLockboxProxy because we do not perform balance checks on newly deployed contracts.
        return balanceChanges;
    }

    /// @notice Parses TOML and initializes contract state for upgrade
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        OPCMUpgrade[] memory parsedUpgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < parsedUpgrades.length; i++) {
            upgrades[parsedUpgrades[i].chainId] = parsedUpgrades[i];
        }

        // === OPCM for U13 ===
        OPCM_V220 = tomlContent.readAddress(".addresses.OPCMUpgradeV220");
        OPCM_V220_PRESTATE = tomlContent.readBytes32(".OPCMUpgradeV220_PRESTATE");
        OPCM_TARGETS.push(OPCM_V220);
        require(IOPContractsManager(OPCM_V220).version().eq("1.7.0"), "Incorrect OPCM - expected version 1.7.0");
        vm.label(OPCM_V220, "OPCMUpgradeV220");

        // === OPCM for U14 and U15 ===
        OPCM_V300 = tomlContent.readAddress(".addresses.OPCMUpgradeV300");
        OPCM_V300_PRESTATE = tomlContent.readBytes32(".OPCMUpgradeV300_PRESTATE");
        OPCM_V300_UPDATE_PRESTATE = tomlContent.readBytes32(".OPCMUpgradeV300_UPDATE_PRESTATE");
        OPCM_TARGETS.push(OPCM_V300);
        require(IOPContractsManager(OPCM_V300).version().eq("1.9.0"), "Incorrect OPCM - expected version 1.9.0");
        vm.label(OPCM_V300, "OPCMUpgradeV300");

        // === OPCM for U16a ===
        OPCM_V410 = tomlContent.readAddress(".addresses.OPCMUpgradeV410");
        OPCM_TARGETS.push(OPCM_V410);
        require(IOPContractsManager(OPCM_V410).version().eq("3.2.0"), "Incorrect OPCM - expected version 3.2.0");
        vm.label(OPCM_V410, "OPCMUpgradeV410");

        // === Standard Validator for U13 ===
        STANDARD_VALIDATOR_V200 = IStandardValidatorV200(tomlContent.readAddress(".addresses.StandardValidatorV200"));
        require(address(STANDARD_VALIDATOR_V200).code.length > 0, "ValidatorV200 not deployed");
        vm.label(address(STANDARD_VALIDATOR_V200), "StandardValidatorV200");

        // === Standard Validator for U14 and U15 ===
        STANDARD_VALIDATOR_V300 = IStandardValidatorV300(tomlContent.readAddress(".addresses.StandardValidatorV300"));
        require(address(STANDARD_VALIDATOR_V300).code.length > 0, "ValidatorV300 not deployed");
        vm.label(address(STANDARD_VALIDATOR_V300), "StandardValidatorV300");

        // === Standard Validator for U16a ===
        STANDARD_VALIDATOR_V410 = IStandardValidatorV410(tomlContent.readAddress(".addresses.StandardValidatorV410"));
        require(address(STANDARD_VALIDATOR_V410).code.length > 0, "ValidatorV410 not deployed");
        vm.label(address(STANDARD_VALIDATOR_V410), "StandardValidatorV410");
    }

    /// @notice Performs the atomic upgrade (U12 to U16a) for all chains
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        IOPContractsManager.OpChainConfig[] memory opChainConfigs =
            new IOPContractsManager.OpChainConfig[](chains.length);

        // === Upgrade to U13 ===
        for (uint256 i = 0; i < chains.length; i++) {
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[i].chainId)),
                absolutePrestate: Claim.wrap(OPCM_V220_PRESTATE)
            });
        }

        (bool success1,) = OPCM_V220.delegatecall(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(success1, "OPCMUpgradeV220: upgrade call failed in _build.");

        // === Validator for U13 ===
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            string memory expErrors = upgrades[chainId].expectedErrorsV220;
            IStandardValidatorV200.InputV200 memory input = IStandardValidatorV200.InputV200({
                proxyAdmin: superchainAddrRegistry.getAddress("ProxyAdmin", chainId),
                sysCfg: superchainAddrRegistry.getAddress("SystemConfigProxy", chainId),
                absolutePrestate: OPCM_V220_PRESTATE,
                l2ChainID: chains[i].chainId
            });

            string memory errors = STANDARD_VALIDATOR_V200.validate(input, true);
            require(errors.eq(expErrors), string.concat("U13 validation failed: ", errors, "; expected: ", expErrors));
        }

        // === Upgrade to U14 ===
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chainId)),
                absolutePrestate: Claim.wrap(OPCM_V300_PRESTATE)
            });
        }

        (bool success2,) = OPCM_V300.delegatecall(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(success2, "OPCMUpgradeV300: upgrade call failed in _build.");

        // === Validator for U14 ===
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            string memory expErrors = upgrades[chainId].expectedErrorsV300;
            IStandardValidatorV300.InputV300 memory input = IStandardValidatorV300.InputV300({
                proxyAdmin: superchainAddrRegistry.getAddress("ProxyAdmin", chainId),
                sysCfg: superchainAddrRegistry.getAddress("SystemConfigProxy", chainId),
                absolutePrestate: OPCM_V300_PRESTATE,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V300.validate(input, true);
            require(errors.eq(expErrors), string.concat("U14 validation failed: ", errors, "; expected: ", expErrors));
        }

        // === Upgrade to U15 ===
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chainId)),
                absolutePrestate: Claim.wrap(OPCM_V300_UPDATE_PRESTATE)
            });
        }

        (bool success3,) =
            OPCM_V300.delegatecall(abi.encodeWithSelector(IOPCMPrestateUpdate.updatePrestate.selector, opChainConfigs));
        require(success3, "OPCMUpgradeV300: updatePrestate call failed in _build.");

        // === Validator for U15 ===
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            string memory expErrors = upgrades[chainId].expectedErrorsV300;

            IStandardValidatorV300.InputV300 memory input = IStandardValidatorV300.InputV300({
                proxyAdmin: superchainAddrRegistry.getAddress("ProxyAdmin", chainId),
                sysCfg: superchainAddrRegistry.getAddress("SystemConfigProxy", chainId),
                absolutePrestate: OPCM_V300_UPDATE_PRESTATE,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V300.validate(input, true);
            require(errors.eq(expErrors), string.concat("U15 validation failed: ", errors, "; expected: ", expErrors));
        }

        // === Upgrade to U16a ===
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chainId)),
                absolutePrestate: upgrades[chainId].absolutePrestate
            });
        }

        // Delegatecall the OPCM.upgrade() function
        (bool success4,) =
            OPCM_V410.delegatecall(abi.encodeWithSelector(IOPContractsManager.upgrade.selector, opChainConfigs));
        require(success4, "OPCMUpgradeV410: upgrade call failed in _build.");
    }

    /// @notice Validates final post-upgrade state
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            bytes32 expAbsolutePrestate = Claim.unwrap(upgrades[chainId].absolutePrestate);
            string memory expErrors = upgrades[chainId].expectedErrorsV410;

            IStandardValidatorV410.InputV410 memory input = IStandardValidatorV410.InputV410({
                proxyAdmin: superchainAddrRegistry.getAddress("ProxyAdmin", chainId),
                sysCfg: superchainAddrRegistry.getAddress("SystemConfigProxy", chainId),
                absolutePrestate: expAbsolutePrestate,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V410.validate(input, true);
            require(errors.eq(expErrors), string.concat("U16a validation failed: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice No code exceptions for this template
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface IOPCMPrestateUpdate {
    function updatePrestate(IOPContractsManager.OpChainConfig[] memory _prestateUpdateInputs) external;
}

/// @notice Validator interfaces
interface IStandardValidatorV300 {
    struct InputV300 {
        address proxyAdmin;
        address sysCfg;
        bytes32 absolutePrestate;
        uint256 l2ChainID;
    }

    function validate(InputV300 memory _input, bool _allowFailure) external view returns (string memory);
    function mipsVersion() external pure returns (string memory);
    function systemConfigVersion() external pure returns (string memory);
}

interface IStandardValidatorV410 {
    struct InputV410 {
        address proxyAdmin;
        address sysCfg;
        bytes32 absolutePrestate;
        uint256 l2ChainID;
    }

    function validate(InputV410 memory _input, bool _allowFailure) external view returns (string memory);
    function mipsVersion() external pure returns (string memory);
    function systemConfigVersion() external pure returns (string memory);
}
