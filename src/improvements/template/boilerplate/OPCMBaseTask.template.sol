// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OPCMBaseTask} from "src/improvements/tasks/types/OPCMBaseTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
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

/// @notice A template contract for configuring OPCMBaseTask templates.
/// Supports: <TODO: add supported tags: e.g. op-contracts/v*.*.*>
contract OPCMBaseTaskTemplate is OPCMBaseTask {
    using stdToml for string;
    using LibString for string;

    /// @notice Struct to store inputs for OPCM.upgrade() function per l2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => Claim) public absolutePrestates;

    /// @notice Returns the storage write permissions required for this task
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        require(false, "TODO: Implement with the correct storage writes.");
        return new string[](0);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // For OPCMUpgradeV200, the OPCMUpgrade struct is used to store the absolutePrestate for each l2 chain.
        OPCMUpgrade[] memory upgrades =
            abi.decode(tomlContent.parseRaw(".opcmUpgrades.absolutePrestates"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < upgrades.length; i++) {
            absolutePrestates[upgrades[i].chainId] = upgrades[i].absolutePrestate;
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

    /// @notice A single call to OPCM.upgrade() is made for all l2 chains.
    function _build() internal override {
        require(false, "TODO: Implement with the correct build logic.");
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        IOPContractsManager.OpChainConfig[] memory opChainConfigs =
            new IOPContractsManager.OpChainConfig[](chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[i].chainId)),
                absolutePrestate: absolutePrestates[chains[i].chainId]
            });
        }

        // See: template/OPCMUpgradeV200.sol for more information on why we expect a revert here.
        (bool success,) = OPCM.call(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(!success, "OPCMUpgradeV200: Call unexpectedly succeeded; expected revert due to non-delegatecall.");
    }

    /// @notice Template developers must override this function and make a call to 'StandardValidator.validate()'.
    function _standardValidatorCheck() internal pure override {
        require(false, "TODO: Call StandardValidator.validate()");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
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

/// TODO: If you need any interfaces from the Optimism monorepo submodule. Define them here instead of importing them.
/// Doing this avoids tight coupling to the monorepo submodule and allows you to update the monorepo submodule
/// without having to update the template.
