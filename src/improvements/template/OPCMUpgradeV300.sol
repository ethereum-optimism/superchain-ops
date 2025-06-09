// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    IOPContractsManager,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {IOPContractsManager} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {OPCMTaskBase} from "../tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice This template supports OPCMV300 upgrade tasks.
contract OPCMUpgradeV300 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice The StandardValidatorV300 address
    IStandardValidatorV300 public STANDARD_VALIDATOR_V300;

    /// @notice Struct to store inputs data for each L2 chain.
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
        string expectedValidationErrors;
    }

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](8);
        storageWrites[0] = "OPCM";
        storageWrites[1] = "SystemConfigProxy";
        storageWrites[2] = "OptimismPortalProxy";
        storageWrites[3] = "L1CrossDomainMessengerProxy";
        storageWrites[4] = "L1ERC721BridgeProxy";
        storageWrites[5] = "L1StandardBridgeProxy";
        storageWrites[6] = "DisputeGameFactoryProxy";
        storageWrites[7] = "AddressManager";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // For OPCMUpgradeV300, the OPCMUpgrade struct is used to store the absolutePrestate and expectedValidationErrors for each l2 chain.
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        OPCM = tomlContent.readAddress(".addresses.OPCM");
        require(OPCM.code.length > 0, "Incorrect OPCM - no code at address");
        require(IOPContractsManager(OPCM).version().eq("1.9.0"), "Incorrect OPCM - expected version 1.9.0");
        vm.label(OPCM, "OPCM");

        STANDARD_VALIDATOR_V300 = IStandardValidatorV300(tomlContent.readAddress(".addresses.StandardValidatorV300"));
        require(
            address(STANDARD_VALIDATOR_V300).code.length > 0, "Incorrect StandardValidatorV300 - no code at address"
        );
        require(
            STANDARD_VALIDATOR_V300.mipsVersion().eq("1.0.0"),
            "Incorrect StandardValidatorV300 - expected mips version 1.0.0"
        );
        require(
            STANDARD_VALIDATOR_V300.systemConfigVersion().eq("2.5.0"),
            "Incorrect StandardValidatorV300 - expected systemConfig version 2.5.0"
        );
        vm.label(address(STANDARD_VALIDATOR_V300), "StandardValidatorV300");
    }

    /// @notice Build the task action for all L2 chains in the task.
    /// A single call to OPCM.upgrade() is made for all L2 chains.
    function _build() internal override {
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

        (bool success,) = OPCM.delegatecall(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(success, "OPCMUpgradeV300: upgrade call failed in _build.");
    }

    /// @notice Validate the task for a given L2 chain.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            bytes32 expAbsolutePrestate = Claim.unwrap(upgrades[chainId].absolutePrestate);
            string memory expErrors = upgrades[chainId].expectedValidationErrors;
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV300.InputV300 memory input = IStandardValidatorV300.InputV300({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: expAbsolutePrestate,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V300.validate({_input: input, _allowFailure: true});

            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice No code exceptions for this template.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}

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
