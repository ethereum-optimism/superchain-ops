// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    ISuperchainConfig,
    ISystemConfig
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import { IProxyAdmin } from "interfaces/universal/IProxyAdmin.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template contract for configuring OPCMTaskBase templates.
/// Supports: op-contracts/v6.0.0
contract OPCMUpgradeV600 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice Struct to store inputs data for each L2 chain.
    struct OPCMUpgrade {
        Claim cannonPrestate;
        Claim cannonKonaPrestate;
        uint256 chainId;
        string expectedValidationErrors;
    }

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice The Standard Validator returned by OPCM
    IOPContractsManagerStandardValidator public STANDARD_VALIDATOR;

    /// @notice OPCM we delegatecall into (must be v4.2.0).
    address public OPCM;

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](10);
        storageWrites[0] = "DisputeGameFactoryProxy";
        storageWrites[1] = "SystemConfigProxy";
        storageWrites[2] = "OptimismPortalProxy";
        storageWrites[3] = "OptimismMintableERC20FactoryProxy";
        storageWrites[4] = "AddressManager";
        storageWrites[5] = "L1CrossDomainMessengerProxy";
        storageWrites[6] = "L1StandardBridgeProxy";
        storageWrites[7] = "L1ERC721BridgeProxy";
        storageWrites[8] = "ProxyAdminOwner";
        storageWrites[9] = "AnchorStateRegistryProxy";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        
        // Load upgrades from TOML
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        // OPCM from TOML; must be v4.2.0
        OPCM = tomlContent.readAddress(".addresses.OPCM");
        OPCM_TARGETS.push(OPCM);
        require(IOPContractsManagerV600(OPCM).version().eq("4.2.0"), "Incorrect OPCM");
        vm.label(OPCM, "OPCM");

        // Fetch the validator directly from OPCM so it doesn't need to be configured in TOML
        address validatorAddr = address(IOPCM(OPCM).opcmStandardValidator());
        require(validatorAddr != address(0), "OPCM returned zero validator");
        require(validatorAddr.code.length > 0, "Validator has no code");
        STANDARD_VALIDATOR = IOPContractsManagerStandardValidator(validatorAddr);
        vm.label(address(STANDARD_VALIDATOR), "OPCMStandardValidator");
    }

    /// @notice Builds the actions for executing the operations.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        IOPContractsManagerV600.OpChainConfig[] memory opChainConfigs =
            new IOPContractsManagerV600.OpChainConfig[](chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV600: Config not found for chain");

            // Optional: enforce non-zero prestates, per U18 notes
            require(
                Claim.unwrap(upgrades[chainId].cannonPrestate) != bytes32(0),
                "OPCMUpgradeV600: cannonPrestate is zero"
            );
            require(
                Claim.unwrap(upgrades[chainId].cannonKonaPrestate) != bytes32(0),
                "OPCMUpgradeV600: cannonKonaPrestate is zero"
            );

            opChainConfigs[i] = IOPContractsManagerV600.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                cannonPrestate: upgrades[chainId].cannonPrestate,
                cannonKonaPrestate: upgrades[chainId].cannonKonaPrestate
            });
        }

        // Delegatecall the OPCM.upgrade() function (new U18 signature)
        (bool ok2,) =
            OPCM_TARGETS[0].delegatecall(abi.encodeWithSelector(IOPContractsManagerV600.upgrade.selector, opChainConfigs));
        require(ok2, "OPCMUpgradeV600: Delegatecall failed in _build.");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            bytes32 expAbsolutePrestate = Claim.unwrap(upgrades[chainId].cannonPrestate);
            string memory expErrors = upgrades[chainId].expectedValidationErrors;
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IOPContractsManagerStandardValidator.ValidationInput memory input = IOPContractsManagerStandardValidator
                .ValidationInput({
                proxyAdmin: IProxyAdmin(proxyAdmin),
                sysCfg: ISystemConfig(sysCfg),
                absolutePrestate: expAbsolutePrestate,
                l2ChainID: chainId
            });

            IOPContractsManagerStandardValidator.ValidationOverrides memory overrides_ =
            IOPContractsManagerStandardValidator.ValidationOverrides({
                l1PAOMultisig: superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId),
                challenger: superchainAddrRegistry.getAddress("Challenger", chainId)
            });

            string memory errors =
                STANDARD_VALIDATOR.validateWithOverrides({_input: input, _allowFailure: true, _overrides: overrides_});

            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

/* ---------- Interfaces ---------- */
/// @notice OPCM Interface.
interface IOPContractsManagerV600 {
    struct OpChainConfig {
        ISystemConfig systemConfigProxy;
        Claim cannonPrestate;
        Claim cannonKonaPrestate;
    }

    function version() external view returns (string memory);

    function upgrade(OpChainConfig[] memory _opChainConfigs) external;

    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidator);
}

/// @notice Interface to retrieve the standard validator from OPCM.
interface IOPCM {
    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidator);
}

/// @notice Validator interface for validateWithOverrides usage.
interface IOPContractsManagerStandardValidator {
    struct ValidationInput {
        IProxyAdmin proxyAdmin;
        ISystemConfig sysCfg;
        bytes32 absolutePrestate;
        uint256 l2ChainID;
    }

    struct ValidationOverrides {
        address l1PAOMultisig;
        address challenger;
    }

    function validate(ValidationInput memory _input, bool _allowFailure) external view returns (string memory);

    function validateWithOverrides(
        ValidationInput memory _input,
        bool _allowFailure,
        ValidationOverrides memory _overrides
    ) external view returns (string memory);

    function version() external view returns (string memory);
}