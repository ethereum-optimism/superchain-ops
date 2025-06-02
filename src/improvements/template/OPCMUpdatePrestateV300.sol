// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ISystemConfig, IProxyAdmin} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {IOPContractsManager} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";

import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {OPCMTaskBase} from "src/improvements/tasks/types/OPCMTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice This template provides OPCM-based absolute prestate updates.
/// Supports: op-contracts/v3.0.0
contract OPCMUpdatePrestateV300 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice The StandardValidatorV300 address
    IStandardValidatorV300 public STANDARD_VALIDATOR_V300;

    /// @notice Struct to store inputs for OPCM.updatePrestate() function per l2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
        string expectedValidationErrors;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice Returns the storage write permissions required for this task
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            console.log("Adding upgrade - chainID: %s, absolutePrestate:", _upgrades[i].chainId);
            console.logBytes32(Claim.unwrap(_upgrades[i].absolutePrestate));
            console.log("Expected errors: %s", _upgrades[i].expectedValidationErrors);
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        OPCM = tomlContent.readAddress(".addresses.OPCM");
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

    /// @notice Before implementing the `_build` function, template developers must consider the following:
    /// 1. Which Multicall contract does this template use — `Multicall3` or `Multicall3Delegatecall`?
    /// 2. Based on the contract, should the target be called using `call` or `delegatecall`?
    /// 3. Ensure that the call to the target uses the appropriate method (`call` or `delegatecall`) accordingly.
    /// Guidelines:
    /// - `Multicall3Delegatecall`:
    ///   If the template inherits from `OPCMTaskBase`, it uses the `Multicall3Delegatecall` contract.
    ///   In this case, calls to the target **must** use `delegatecall`, e.g.:
    ///   `(bool success,) = OPCM.delegatecall(abi.encodeWithSelector(IOPCMPrestateUpdate.upgrade.selector, opChainConfigs));`
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

        (bool success,) =
            OPCM.delegatecall(abi.encodeWithSelector(IOPCMPrestateUpdate.updatePrestate.selector, opChainConfigs));
        require(success, "OPCM.updatePrestate() failed");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
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

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}

interface IOPCMPrestateUpdate {
    function updatePrestate(IOPContractsManager.OpChainConfig[] memory _prestateUpdateInputs) external;
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
