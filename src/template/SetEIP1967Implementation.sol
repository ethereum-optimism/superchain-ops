// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";
import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {IProxy} from "@eth-optimism-bedrock/interfaces/universal/IProxy.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template contract for setting the EIP-1967 implementation address across 'n' number of chains where all
/// chains share the same ProxyAdminOwner.
/// NOTE: This template calls the `upgrade` function on the ProxyAdmin contract. It does not provide reinitialization
/// of the implementation via the `upgradeToAndCall` function. For that, you'll need to use a different template.
contract SetEIP1967Implementation is L2TaskBase {
    using stdToml for string;

    /// @notice The new implementation address.
    address public newImplementation;

    /// @notice This is the identifier that will be used to determine which EIP1967 proxy contract is targeted.
    /// This is the name of the contract that is being upgraded.
    string public contractIdentifier;

    /// @notice The ProxyAdmin contract.
    IProxyAdmin public proxyAdmin;

    /// @notice Stores the chain information after setup.
    SuperchainAddressRegistry.ChainInfo internal activeChainInfo;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        require(bytes(contractIdentifier).length > 0, "contractIdentifier must be set");
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "ProxyAdminOwner";
        storageWrites[1] = contractIdentifier;
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();
        string memory toml = vm.readFile(_taskConfigFilePath);

        newImplementation = toml.readAddress(".newImplementation");
        require(newImplementation != address(0), "newImplementation must be set in the config file.");

        contractIdentifier = toml.readString(".contractIdentifier");
        require(bytes(contractIdentifier).length > 0, "contractIdentifier must be set in the config file.");

        require(_chains.length > 0, "At least one chain must be specified.");
        activeChainInfo = _chains[0]; // Store the ChainInfo struct
        proxyAdmin = IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", activeChainInfo.chainId)); // ProxyAdmin is the same for all chains.

        super._templateSetup(_taskConfigFilePath, _rootSafe);
    }

    /// @notice Builds the actions for executing the operations.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address proxy = superchainAddrRegistry.getAddress(contractIdentifier, chainId);
            proxyAdmin.upgrade(payable(proxy), newImplementation);
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    /// We only check that the new implementation is set for each chain.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address proxy = superchainAddrRegistry.getAddress(contractIdentifier, chainId);
            vm.prank(address(0));
            address implementation = IProxy(payable(proxy)).implementation();
            require(implementation == newImplementation, "Implementation mismatch");
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
