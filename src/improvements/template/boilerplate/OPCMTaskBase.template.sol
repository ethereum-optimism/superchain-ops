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

import {OPCMTaskBase} from "src/improvements/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// TODO: If you need any interfaces from the Optimism monorepo submodule. Define them here instead of importing them.
/// Doing this avoids tight coupling to the monorepo submodule and allows you to update the monorepo submodule
/// without having to update the template (Remove this comment when done).

/// @notice A template contract for configuring OPCMTaskBase templates.
/// Supports: <TODO: add supported tags: e.g. op-contracts/v*.*.*>
contract OPCMTaskBaseTemplate is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

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
        require(false, "TODO: Implement with the correct storage writes.");
        return new string[](0);
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {
        require(false, "TODO: Implement with the correct balance changes.");
        return new string[](0);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // OPCMUpgrade struct is used to store the absolutePrestate and expectedValidationErrors for each l2 chain.
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        OPCM = tomlContent.readAddress(".addresses.OPCM");
        require(false, "TODO: Perform an OPCM version check e.g. see comments below.");
        // require(IOPContractsManager(OPCM).version().eq("1.6.0"), "Incorrect OPCM");
        vm.label(OPCM, "OPCM");

        require(false, "TODO: Perform a StandardValidatorV200 version check e.g. see comments below.");
        // STANDARD_VALIDATOR_V200 = IStandardValidatorV200(tomlContent.readAddress(".addresses.StandardValidatorV200"));
        // require(STANDARD_VALIDATOR_V200.disputeGameFactoryVersion().eq("1.0.1"), "Incorrect StandardValidatorV200");
        // vm.label(address(STANDARD_VALIDATOR_V200), "StandardValidatorV200");
        require(false, "TODO: Implement with the correct template setup.");
    }

    /// @notice Before implementing the `_build` function, task developers must consider the following:
    /// 1. Which Multicall contract does this template use — `Multicall3` or `Multicall3Delegatecall`?
    /// 2. Based on the contract, should the target be called using `call` or `delegatecall`?
    /// 3. Ensure that the call to the target uses the appropriate method (`call` or `delegatecall`) accordingly.
    /// Guidelines:
    /// - `Multicall3Delegatecall`:
    ///   If the template inherits from `OPCMTaskBase`, it uses the `Multicall3Delegatecall` contract.
    ///   In this case, calls to the target **must** use `delegatecall`, e.g.:
    ///   `(bool success,) = OPCM.delegatecall(abi.encodeWithSelector(IOPContractsManager.upgrade, opChainConfigs));
    /// WARNING: Any state written to in this function will be reverted after the build function has been run.
    /// Do not rely on setting global variables in this function.
    function _build() internal override {
        // Do not set global variables in this function, see natspec above.
        require(false, "TODO: Implement with the correct build logic.");
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

        // TODO: This may execute the OPCM.upgrade() function or a different OPCM function.
        // We're using the OPCM.upgrade() function as an example here.
        (bool success,) =
            OPCM.delegatecall(abi.encodeWithSelector(IOPContractsManager.upgrade.selector, opChainConfigs));
        require(success, "OPCMTaskBaseTemplate: Delegatecall failed in _build.");
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
            chainId;
            expAbsolutePrestate;
            expErrors;
            proxyAdmin;
            sysCfg;
            require(false, "TODO: Implement with the correct validation logic.");
            require(false, "TODO: Call StandardValidator.validate()");
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        require(
            false, "TODO: Implement the logic to return a list of addresses that should not be checked for code length."
        );
        return new address[](0);
    }
}
