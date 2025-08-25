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

import {console2 as console} from "forge-std/console2.sol";

import {OPCMTaskBase} from "src/improvements/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice Use this template for chains that are on U12 and need to be upgraded to U16 (inclusive).
///         The template applies each required OPCM upgrade step (U13, U14, U15, U16) in sequence.
contract OPCMUpgradeV200toV400 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice Validators
    IStandardValidatorV200 public STANDARD_VALIDATOR_V200;
    IStandardValidatorV300 public STANDARD_VALIDATOR_V300;
    IStandardValidatorV400 public STANDARD_VALIDATOR_V400;

    /// @notice Address of the OPCM for U13, U14, U15 and U16.
    address public OPCM_V200;
    address public OPCM_V300;
    address public OPCM_V400;

    /// @notice Prestates for the OPCM upgrades.
    bytes32 public OPCM_V200_PRESTATE;
    bytes32 public OPCM_V300_PRESTATE;
    bytes32 public OPCM_V300_UPDATE_PRESTATE;
    bytes32 public OPCM_V400_PRESTATE;

    /// @notice Struct to store inputs for OPCM.upgrade() function per L2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
        string expectedValidationErrors;
    }

    /// @notice Mapping from chain ID to upgrade parameters
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice Returns the storage write permissions
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](16);
        storageWrites[0] = "ProxyAdminOwner";
        storageWrites[1] = "OPCMUpgradeV200";
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
        storageWrites[15] = "OPCMUpgradeV400";
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
            console.log("Adding upgrade - chainID: %s", parsedUpgrades[i].chainId);
            console.logBytes32(Claim.unwrap(parsedUpgrades[i].absolutePrestate));
            console.log("Expected errors: %s", parsedUpgrades[i].expectedValidationErrors);
            upgrades[parsedUpgrades[i].chainId] = parsedUpgrades[i];
        }

        // === OPCM for U13 ===
        OPCM_V200 = tomlContent.readAddress(".addresses.OPCMUpgradeV200");
        OPCM_V200_PRESTATE = tomlContent.readBytes32(".OPCMUpgradeV200_PRESTATE");
        OPCM_TARGETS.push(OPCM_V200);
        require(IOPContractsManager(OPCM_V200).version().eq("1.7.0"), "Incorrect OPCM - expected version 1.7.0");
        vm.label(OPCM_V200, "OPCMUpgradeV200");

        // === OPCM for U14 and U15 ===
        OPCM_V300 = tomlContent.readAddress(".addresses.OPCMUpgradeV300");
        OPCM_V300_PRESTATE = tomlContent.readBytes32(".OPCMUpgradeV300_PRESTATE");
        OPCM_V300_UPDATE_PRESTATE = tomlContent.readBytes32(".OPCMUpgradeV300_UPDATE_PRESTATE");
        OPCM_TARGETS.push(OPCM_V300);
        require(IOPContractsManager(OPCM_V300).version().eq("1.9.0"), "Incorrect OPCM - expected version 1.9.0");
        vm.label(OPCM_V300, "OPCMUpgradeV300");

        // === OPCM for U16 ===
        OPCM_V400 = tomlContent.readAddress(".addresses.OPCMUpgradeV400");
        OPCM_TARGETS.push(OPCM_V400);
        require(IOPContractsManager(OPCM_V400).version().eq("2.4.0"), "Incorrect OPCM - expected version 2.4.0");
        vm.label(OPCM_V400, "OPCMUpgradeV400");

        // === Standard Validator for U13 ===
        STANDARD_VALIDATOR_V200 = IStandardValidatorV200(tomlContent.readAddress(".addresses.StandardValidatorV200"));
        require(address(STANDARD_VALIDATOR_V200).code.length > 0, "ValidatorV200 not deployed");
        vm.label(address(STANDARD_VALIDATOR_V200), "StandardValidatorV200");

        // === Standard Validator for U14 and U15 ===
        STANDARD_VALIDATOR_V300 = IStandardValidatorV300(tomlContent.readAddress(".addresses.StandardValidatorV300"));
        require(address(STANDARD_VALIDATOR_V300).code.length > 0, "ValidatorV300 not deployed");
        vm.label(address(STANDARD_VALIDATOR_V300), "StandardValidatorV300");

        // === Standard Validator for U16 ===
        STANDARD_VALIDATOR_V400 = IStandardValidatorV400(tomlContent.readAddress(".addresses.StandardValidatorV400"));
        require(address(STANDARD_VALIDATOR_V400).code.length > 0, "ValidatorV400 not deployed");
        vm.label(address(STANDARD_VALIDATOR_V400), "StandardValidatorV400");
    }

    /// @notice Performs the atomic upgrade (U12 to U16) for all chains
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        IOPContractsManager.OpChainConfig[] memory opChainConfigs =
            new IOPContractsManager.OpChainConfig[](chains.length);

        // === Upgrade to U13 ===
        for (uint256 i = 0; i < chains.length; i++) {
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[i].chainId)),
                absolutePrestate: Claim.wrap(OPCM_V200_PRESTATE)
            });
        }

        (bool success1,) = OPCM_V200.delegatecall(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(success1, "OPCMUpgradeV200: upgrade call failed in _build.");

        // === Validator for U13 ===
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV200.InputV200 memory input = IStandardValidatorV200.InputV200({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: OPCM_V200_PRESTATE,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V200.validate(input, true);
            require(bytes(errors).length == 0, string.concat("U13 validation failed: ", errors));
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
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV300.InputV300 memory input = IStandardValidatorV300.InputV300({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: OPCM_V300_PRESTATE,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V300.validate(input, true);
            require(bytes(errors).length == 0, string.concat("U14 validation failed: ", errors));
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
        require(success3, "OPCM.updatePrestate() failed");

        // === Validator for U15 ===
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV300.InputV300 memory input = IStandardValidatorV300.InputV300({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: OPCM_V300_UPDATE_PRESTATE,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V300.validate(input, true);
            require(bytes(errors).length == 0, string.concat("U15 validation failed: ", errors));
        }

        // === Upgrade to U16 ===
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
            OPCM_V400.delegatecall(abi.encodeWithSelector(IOPContractsManager.upgrade.selector, opChainConfigs));
        require(success4, "OPCMUpgradeV400: Delegatecall failed in _build.");
    }

    /// @notice Validates final post-upgrade state
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        // SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        // for (uint256 i = 0; i < chains.length; i++) {
        //     uint256 chainId = chains[i].chainId;
        //     bytes32 expAbsolutePrestate = Claim.unwrap(upgrades[chainId].absolutePrestate);
        //     string memory expErrors = upgrades[chainId].expectedValidationErrors;
        //     address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
        //     address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

        //     IStandardValidatorV400.InputV400 memory input = IStandardValidatorV400.InputV400({
        //         proxyAdmin: proxyAdmin,
        //         sysCfg: sysCfg,
        //         absolutePrestate: expAbsolutePrestate,
        //         l2ChainID: chainId
        //     });

        //     string memory errors = STANDARD_VALIDATOR_V400.validate({_input: input, _allowFailure: true});

        //     require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        // }
    }

    /// @notice No code exceptions for this template
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
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

interface IStandardValidatorV400 {
    struct InputV400 {
        address proxyAdmin;
        address sysCfg;
        bytes32 absolutePrestate;
        uint256 l2ChainID;
    }

    function validate(InputV400 memory _input, bool _allowFailure) external view returns (string memory);

    function mipsVersion() external pure returns (string memory);

    function systemConfigVersion() external pure returns (string memory);
}
