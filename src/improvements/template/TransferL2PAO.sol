// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

/// @notice Template contract to transfer ownership of the L2 ProxyAdmin to the aliased L1 ProxyAdmin owner.
/// The user provides the unaliased L1 PAO owner, and this template aliases the address and transfers ownership.
/// ATTENTION: Please use caution when using this template. Transferring ownership is high risk.
contract TransferL2PAO is L2TaskBase {
    using stdToml for string;

    /// @notice The aliased L1 PAO owner.
    address public aliasedNewOwner;

    /// @notice Returns the safe address string identifier
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "ProxyAdmin";
        return storageWrites;
    }

    /// @notice Sets up the template with the new owner from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory toml = vm.readFile(taskConfigFilePath);

        // New owner address. This address is unaliased.
        address newOwnerToAlias = abi.decode(vm.parseToml(toml, ".newOwnerToAlias"), (address));
        // Apply the alias to the new owner.
        aliasedNewOwner = AddressAliasHelper.applyL1ToL2Alias(newOwnerToAlias);

        // only allow one chain to be modified at a time with this template
        SuperchainAddressRegistry.ChainInfo[] memory _chains =
            abi.decode(vm.parseToml(toml, ".l2chains"), (SuperchainAddressRegistry.ChainInfo[]));
        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");
    }

    /// @notice Builds the actions for transferring ownership of the proxy admin.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chainId));
            proxyAdmin.transferOwnership(aliasedNewOwner);
        }
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[i].chainId));
            assertEq(proxyAdmin.owner(), aliasedNewOwner, "aliased new owner not set correctly");
        }
    }

    /// @notice Aliased new owner is a code exception. This is because the aliased address is not a contract.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        address[] memory codeExceptions = new address[](1);
        codeExceptions[0] = aliasedNewOwner;
        return codeExceptions;
    }
}
