// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ISystemConfig, IProxyAdmin} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {IOPContractsManager} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";

import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice This template provides OPCM-based absolute prestate updates.
/// Supports: op-contracts/v4.1.0
contract OPCMUpdatePrestateV410 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice Struct to store inputs for OPCM.updatePrestate() function per l2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
        string expectedValidationErrors;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice The Standard Validator returned by OPCM
    IOPContractsManagerStandardValidator public STANDARD_VALIDATOR;

    /// @notice Returns the storage write permissions required for this task
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            console.log("Adding upgrade - chainID: %s, absolutePrestate:", _upgrades[i].chainId);
            console.logBytes32(Claim.unwrap(_upgrades[i].absolutePrestate));
            console.log("Expected errors: %s", _upgrades[i].expectedValidationErrors);
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        address OPCM = tomlContent.readAddress(".addresses.OPCM");
        OPCM_TARGETS.push(OPCM);
        require(IOPContractsManager(OPCM).version().eq("3.2.0"), "Incorrect OPCM - expected version 3.2.0");
        vm.label(OPCM, "OPCM");

        // Fetch the validator directly from OPCM so it doesn't need to be configured in TOML
        address validatorAddr = address(IOPCM(OPCM).opcmStandardValidator());
        require(validatorAddr != address(0), "OPCM returned zero validator");
        require(validatorAddr.code.length > 0, "Validator has no code");
        STANDARD_VALIDATOR = IOPContractsManagerStandardValidator(validatorAddr);
        vm.label(address(STANDARD_VALIDATOR), "OPCMStandardValidator");
    }

    /// @notice Before implementing the `_build` function, template developers must consider the following:
    /// 1. Which Multicall contract does this template use — `Multicall3` or `Multicall3Delegatecall`?
    /// 2. Based on the contract, should the target be called using `call` or `delegatecall`?
    /// 3. Ensure that the call to the target uses the appropriate method (`call` or `delegatecall`) accordingly.
    /// Guidelines:
    /// - `Multicall3Delegatecall`:
    ///   If the template inherits from `OPCMTaskBase`, it uses the `Multicall3Delegatecall` contract.
    ///   In this case, calls to the target **must** use `delegatecall`, e.g.:
    ///   `(bool success,) = OPCM.delegatecall(abi.encodeWithSelector(IOPCMPrestateUpdate.upgrade.selector, opChainConfigs));`
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

        (bool success,) = OPCM_TARGETS[0].delegatecall(
            abi.encodeWithSelector(IOPCMPrestateUpdate.updatePrestate.selector, opChainConfigs)
        );
        require(success, "OPCM.updatePrestate() failed");
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

interface IOPCMPrestateUpdate {
    function updatePrestate(IOPContractsManager.OpChainConfig[] memory _prestateUpdateInputs) external;
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
