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

/// @notice A template contract for configuring OPCMTaskBase templates.
/// Supports: op-contracts/v4.0.0-rc.2>
contract OPCMUpgradeV400 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    IStandardValidatorV400 public STANDARD_VALIDATOR_V400;

    /// @notice Struct to store inputs data for each L2 chain.
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
        string expectedValidationErrors;
    }

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice Returns the storage write permissions required for this task
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](10);
        storageWrites[0] = "ProxyAdminOwner";
        storageWrites[1] = "OPCM";
        storageWrites[2] = "SuperchainConfig";
        storageWrites[3] = "DisputeGameFactoryProxy";
        storageWrites[4] = "SystemConfigProxy";
        storageWrites[5] = "OptimismPortalProxy";
        storageWrites[6] = "AddressManager";
        storageWrites[7] = "L1CrossDomainMessengerProxy";
        storageWrites[8] = "L1StandardBridgeProxy";
        storageWrites[9] = "L1ERC721BridgeProxy";
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

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // OPCMUpgrade struct is used to store the absolutePrestate and expectedValidationErrors for each l2 chain.
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        OPCM = tomlContent.readAddress(".addresses.OPCM");
        require(IOPContractsManager(OPCM).version().eq("2.4.0"), "Incorrect OPCM");
        vm.label(OPCM, "OPCM");

        STANDARD_VALIDATOR_V400 = IStandardValidatorV400(tomlContent.readAddress(".addresses.StandardValidatorV400"));
        require(
            address(STANDARD_VALIDATOR_V400).code.length > 0, "Incorrect StandardValidatorV400 - no code at address"
        );
        vm.label(address(STANDARD_VALIDATOR_V400), "StandardValidatorV400");
    }

    /// @notice Before implementing the `_build` function, task developers must consider the following:
    /// 1. Which Multicall contract does this template use — `Multicall3` or `Multicall3Delegatecall`?
    /// 2. Based on the contract, should the target be called using `call` or `delegatecall`?
    /// 3. Ensure that the call to the target uses the appropriate method (`call` or `delegatecall`) accordingly.
    /// Guidelines:
    /// - `Multicall3Delegatecall`:
    ///   If the template inherits from `OPCMTaskBase`, it uses the `Multicall3Delegatecall` contract.
    ///   In this case, calls to the target **must** use `delegatecall`, e.g.:
    ///   `(bool success,) = OPCM.delegatecall(abi.encodeWithSelector(IOPContractsManager.upgrade, opChainConfigs));`
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

        // Delegatecall the OPCM.upgrade() function
        (bool success,) =
            OPCM.delegatecall(abi.encodeWithSelector(IOPContractsManager.upgrade.selector, opChainConfigs));
        require(success, "OPCMUpgradeV400: Delegatecall failed in _build.");
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

            IStandardValidatorV400.InputV400 memory input = IStandardValidatorV400.InputV400({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: expAbsolutePrestate,
                l2ChainID: chainId
            });

            string memory errors = STANDARD_VALIDATOR_V400.validate({_input: input, _allowFailure: true});

            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
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
