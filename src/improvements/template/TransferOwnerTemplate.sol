// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";

/// @title TransferOwnerTemplate
/// @notice Template contract for transferring ownership of the proxy admin
contract TransferOwnerTemplate is L2TaskBase {
    using stdToml for string;

    /// @notice new owner address
    address public newOwner;

    /// @notice Returns the safe address string identifier
    /// @return The string "ProxyAdminOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
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
        string memory toml = vm.readFile(taskConfigFilePath);
        newOwner = toml.readAddress(".newOwner");
        // only allow one chain to be modified at a time with this 
        AddressRegistry.ChainInfo[] memory _chains = addrRegistry.readChainsFromToml(taskConfigFilePath, ".l2chains");
        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");
    }

    /// @notice Builds the actions for transferring ownership of the proxy admin
    function _build() internal override {
        AddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            // View only, filtered out by MultisigTask.sol
            ProxyAdmin proxyAdmin = ProxyAdmin(addrRegistry.getAddress("ProxyAdmin", chainId));

            // Mutative call, recorded by MultisigTask.sol for generating multisig calldata
            proxyAdmin.transferOwnership(newOwner);
        }
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        AddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            ProxyAdmin proxyAdmin = ProxyAdmin(addrRegistry.getAddress("ProxyAdmin", chains[i].chainId));
            assertEq(proxyAdmin.owner(), newOwner, "new owner not set correctly");
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
