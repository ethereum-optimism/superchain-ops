pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/improvements/AddressRegistry.sol";

/// @title TransferOwnerTemplate
/// @notice Template contract for transferring ownership of the proxy admin
contract TransferOwnerTemplate is MultisigTask {
    /// @notice new owner address
    address public newOwner;

    /// @notice Returns the safe address string identifier
    /// @return The string "SystemConfigOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "SystemConfigOwner";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions, in this case, only the ProxyAdmin is returned
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "ProxyAdmin";
        return storageWrites;
    }

    /// @notice Sets up the template with the new owner from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        newOwner = abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".newOwner"), (address));
        /// only allow one chain to be modified at a time with this template
        Addresses.ChainInfo[] memory _chains =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".l2chains"), (Addresses.ChainInfo[]));
        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");
    }

    /// @notice Builds the actions for setting gas limits for a specific L2 chain ID
    /// @param chainId The ID of the L2 chain to configure
    function _build(uint256 chainId) internal override {
        /// View only, filtered out by MultisigTask.sol
        ProxyAdmin proxyAdmin = ProxyAdmin(addresses.getAddress("ProxyAdmin", chainId));

        /// Mutative call, recorded by MultisigTask.sol for generating multisig calldata
        proxyAdmin.transferOwnership(newOwner);
    }

    /// @notice Validates that gas limits were set correctly for the specified chain ID
    /// @param chainId The ID of the L2 chain to validate
    function _validate(uint256 chainId) internal view override {
        ProxyAdmin proxyAdmin = ProxyAdmin(addresses.getAddress("ProxyAdmin", chainId));

        assertEq(proxyAdmin.owner(), newOwner, "new owner not set correctly");
    }
}
