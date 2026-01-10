// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Claim } from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import { VmSafe } from "forge-std/Vm.sol";
import { stdToml } from "forge-std/StdToml.sol";
import { console2 as console } from "forge-std/console2.sol";
import { LibString } from "solady/utils/LibString.sol";

import { OPCMTaskBase } from "src/tasks/types/OPCMTaskBase.sol";
import { SuperchainAddressRegistry } from "src/SuperchainAddressRegistry.sol";
import { Action } from "src/libraries/MultisigTypes.sol";

/// @notice This template provides OPCM-based absolute prestate updates.
/// Supports: op-contracts/v6.0.0
contract OPCMUpdatePrestateV600 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice Struct to store inputs for OPCM.updatePrestate() function per l2 chain
    struct OPCMUpgrade {
        Claim cannonPrestate;
        Claim cannonKonaPrestate;
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

            // U18 requirement: BOTH prestates must be non-zero.
            require(Claim.unwrap(_upgrades[i].cannonPrestate) != bytes32(0), "OPCMUpdatePrestateV600: cannon=0");
            require(Claim.unwrap(_upgrades[i].cannonKonaPrestate) != bytes32(0), "OPCMUpdatePrestateV600: kona=0");

            console.log("Adding prestate update - chainID: %s", _upgrades[i].chainId);
            console.log("  cannonPrestate:");
            console.logBytes32(Claim.unwrap(_upgrades[i].cannonPrestate));
            console.log("  cannonKonaPrestate:");
            console.logBytes32(Claim.unwrap(_upgrades[i].cannonKonaPrestate));
            console.log("  Expected errors: %s", _upgrades[i].expectedValidationErrors);

            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        address OPCM = tomlContent.readAddress(".addresses.OPCM");
        OPCM_TARGETS.push(OPCM);
        require(IOPContractsManagerV600(OPCM).version().eq("6.0.0"), "Incorrect OPCM - expected version 6.0.0");
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
        IOPContractsManagerV600.UpdatePrestateInput[] memory inputs =
            new IOPContractsManagerV600.UpdatePrestateInput[](chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpdatePrestate: Config not found for chain");

            // U18 requirement: BOTH must be non-zero
            require(Claim.unwrap(upgrades[chainId].cannonPrestate) != bytes32(0), "OPCMUpdatePrestate: cannon=0");
            require(Claim.unwrap(upgrades[chainId].cannonKonaPrestate) != bytes32(0), "OPCMUpdatePrestate: kona=0");

            inputs[i] = IOPContractsManagerV600.UpdatePrestateInput({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                cannonPrestate: upgrades[chainId].cannonPrestate,
                cannonKonaPrestate: upgrades[chainId].cannonKonaPrestate
            });
        }

        (bool success, bytes memory returnData) = OPCM_TARGETS[0].delegatecall(
            abi.encodeWithSelector(IOPContractsManagerV600.updatePrestate.selector, inputs)
        );
        if (!success) {
            if (returnData.length > 0) {
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
            revert("OPCM.updatePrestate() failed");
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        // Cache standard validator's expected values (same for all chains)
        address standardL1PAO = STANDARD_VALIDATOR.l1PAOMultisig();
        address standardChallenger = STANDARD_VALIDATOR.challenger();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            IOPContractsManagerStandardValidator.ValidationInputDev memory input = IOPContractsManagerStandardValidator
                .ValidationInputDev({
                sysCfg: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                cannonPrestate: Claim.unwrap(upgrades[chainId].cannonPrestate),
                cannonKonaPrestate: Claim.unwrap(upgrades[chainId].cannonKonaPrestate),
                l2ChainID: chainId,
                proposer: superchainAddrRegistry.getAddress("Proposer", chainId)
            });

            // Compute overrides: non-zero only if chain differs from standard
            address l1PAOOverride = superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId);
            address challengerOverride = superchainAddrRegistry.getAddress("Challenger", chainId);

            l1PAOOverride = l1PAOOverride != standardL1PAO ? l1PAOOverride : address(0);
            challengerOverride = challengerOverride != standardChallenger ? challengerOverride : address(0);

            string memory errors;
            if (l1PAOOverride != address(0) || challengerOverride != address(0)) {
                errors = STANDARD_VALIDATOR.validateWithOverrides({
                    _input: input,
                    _allowFailure: true,
                    _overrides: IOPContractsManagerStandardValidator.ValidationOverrides({
                        l1PAOMultisig: l1PAOOverride,
                        challenger: challengerOverride
                    })
                });
            } else {
                errors = STANDARD_VALIDATOR.validate({_input: input, _allowFailure: true});
            }

            string memory expErrors = upgrades[chainId].expectedValidationErrors;
            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

/* ---------- Interfaces ---------- */
/// @notice OPCM Interface.
interface IOPContractsManagerV600 {
    struct UpdatePrestateInput {
        ISystemConfig systemConfigProxy;
        Claim cannonPrestate;
        Claim cannonKonaPrestate;
    }

    function version() external view returns (string memory);

    function updatePrestate(UpdatePrestateInput[] memory _prestateUpdateInputs) external;

    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidator);
}

/// @notice Interface to retrieve the standard validator from OPCM.
interface IOPCM {
    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidator);
}

/// @notice Validator interface for validateWithOverrides usage.
interface IOPContractsManagerStandardValidator {
    struct ValidationInputDev {
        ISystemConfig sysCfg;
        bytes32 cannonPrestate;
        bytes32 cannonKonaPrestate;
        uint256 l2ChainID;
        address proposer;
    }

    struct ValidationOverrides {
        address l1PAOMultisig;
        address challenger;
    }

    function validate(ValidationInputDev memory _input, bool _allowFailure) external view returns (string memory);
    function l1PAOMultisig() external view returns (address);
    function challenger() external view returns (address);
    function validateWithOverrides(
        ValidationInputDev memory _input,
        bool _allowFailure,
        ValidationOverrides memory _overrides
    ) external view returns (string memory);

    function version() external view returns (string memory);
}

interface ISystemConfig {
    struct Addresses {
        address l1CrossDomainMessenger;
        address l1ERC721Bridge;
        address l1StandardBridge;
        address optimismPortal;
        address optimismMintableERC20Factory;
        address delayedWETH;
        address opcm;
    }

    function getAddresses() external view returns (Addresses memory);
}