// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    IOPContractsManager,
    ISuperchainConfig,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template contract for configuring OPCMTaskBase templates.
/// Supports: op-contracts/v5.0.0
contract OPCMUpgradeV500 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    IStandardValidatorV500 public STANDARD_VALIDATOR_V500;

    /// @notice Struct to store inputs data for each L2 chain.
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
        string expectedValidationErrors;
    }

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice Shared SuperchainConfig proxy to upgrade first.
    ISuperchainConfig public SUPERCHAIN_CONFIG;
    IProxyAdmin public SUPERCHAIN_CONFIG_PROXY_ADMIN;

    /// @notice OPCM we delegatecall into (must be v4.2.0).
    address public OPCM;

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](11);
        storageWrites[0] = "SuperchainConfig";
        storageWrites[1] = "DisputeGameFactoryProxy";
        storageWrites[2] = "SystemConfigProxy";
        storageWrites[3] = "OptimismPortalProxy";
        storageWrites[4] = "OptimismMintableERC20FactoryProxy";
        storageWrites[5] = "AddressManager";
        storageWrites[6] = "L1CrossDomainMessengerProxy";
        storageWrites[7] = "L1StandardBridgeProxy";
        storageWrites[8] = "L1ERC721BridgeProxy";
        storageWrites[9] = "ProxyAdminOwner";
        storageWrites[10] = "AnchorStateRegistryProxy";
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

        // Load shared SuperchainConfig proxy
        SUPERCHAIN_CONFIG = ISuperchainConfig(tomlContent.readAddress(".addresses.SuperchainConfig"));
        require(address(SUPERCHAIN_CONFIG).code.length > 0, "SuperchainConfig has no code");
        vm.label(address(SUPERCHAIN_CONFIG), "SuperchainConfig");

        SUPERCHAIN_CONFIG_PROXY_ADMIN = IProxyAdmin(tomlContent.readAddress(".addresses.SuperchainConfigProxyAdmin"));
        require(
            address(SUPERCHAIN_CONFIG_PROXY_ADMIN).code.length > 0,
            "Incorrect SuperchainConfigProxyAdmin - no code at address"
        );
        vm.label(address(SUPERCHAIN_CONFIG_PROXY_ADMIN), "SuperchainConfigProxyAdmin");

        // OPCMUpgrade struct is used to store the absolutePrestate and expectedValidationErrors for each l2 chain.
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        OPCM = tomlContent.readAddress(".addresses.OPCM");
        OPCM_TARGETS.push(OPCM);
        require(IOPContractsManager(OPCM).version().eq("4.2.0"), "Incorrect OPCM");
        vm.label(OPCM, "OPCM");

        STANDARD_VALIDATOR_V500 = IStandardValidatorV500(tomlContent.readAddress(".addresses.StandardValidatorV500"));
        require(
            address(STANDARD_VALIDATOR_V500).code.length > 0, "Incorrect StandardValidatorV500 - no code at address"
        );
        vm.label(address(STANDARD_VALIDATOR_V500), "StandardValidatorV500");
    }

    /// @notice Builds the actions for executing the operations.
    function _build(address) internal override {
      {
            string memory current = SUPERCHAIN_CONFIG.version();
            address targetImpl = IOPContractsManager(OPCM_TARGETS[0]).implementations().superchainConfigImpl;
            string memory target = ISuperchainConfig(targetImpl).version();
            if (keccak256(bytes(current)) != keccak256(bytes(target))) {
                (bool ok1,) = OPCM_TARGETS[0].delegatecall(
                    abi.encodeCall(
                        IOPContractManagerV500.upgradeSuperchainConfig,
                        (SUPERCHAIN_CONFIG, SUPERCHAIN_CONFIG_PROXY_ADMIN)
                    )
                );
                require(ok1, "OPCMUpgradeSuperchainConfigV500: Delegatecall failed in _build.");
            }
        }

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

        // Delegatecall the OPCM.upgrade() function
        (bool ok2,) =
            OPCM_TARGETS[0].delegatecall(abi.encodeWithSelector(IOPContractsManager.upgrade.selector, opChainConfigs));
        require(ok2, "OPCMUpgradeV500: Delegatecall failed in _build.");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        require(
            EIP1967Helper.getImplementation(address(SUPERCHAIN_CONFIG))
                == IOPContractsManager(OPCM_TARGETS[0]).implementations().superchainConfigImpl,
            "OPCMUpgradeSuperchainConfigV500: Incorrect SuperchainConfig implementation after upgradeSuperchainConfig"
        );
        require(
            SUPERCHAIN_CONFIG.version().eq("2.4.0"),
            "OPCMUpgradeSuperchainConfigV500: Incorrect SuperchainConfig version after upgradeSuperchainConfig"
        );

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            bytes32 expAbsolutePrestate = Claim.unwrap(upgrades[chainId].absolutePrestate);
            string memory expErrors = upgrades[chainId].expectedValidationErrors;
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV500.InputV500 memory input = IStandardValidatorV500.InputV500({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: expAbsolutePrestate,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V500.validate({_input: input, _allowFailure: true});

            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface IOPContractManagerV500 {
    function upgradeSuperchainConfig(ISuperchainConfig _superchainConfig, IProxyAdmin _superchainConfigProxyAdmin)
        external;
}

interface IStandardValidatorV500 {
    struct InputV500 {
        address proxyAdmin;
        address sysCfg;
        bytes32 absolutePrestate;
        uint256 l2ChainID;
    }

    function validate(InputV500 memory _input, bool _allowFailure) external view returns (string memory);
}
