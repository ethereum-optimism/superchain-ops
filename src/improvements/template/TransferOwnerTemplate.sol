// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

/// @notice Template contract for transferring ownership of the proxy admin.
contract TransferOwnerTemplate is L2TaskBase {
    /// @notice new owner address
    address public newOwner;

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
        newOwner = abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".newOwner"), (address));
        // only allow one chain to be modified at a time with this template
        SuperchainAddressRegistry.ChainInfo[] memory _chains = abi.decode(
            vm.parseToml(vm.readFile(taskConfigFilePath), ".l2chains"), (SuperchainAddressRegistry.ChainInfo[])
        );
        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");
    }

    /// @notice Builds the actions for transferring ownership of the proxy admin.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chainId));
            proxyAdmin.transferOwnership(newOwner);
        }
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[i].chainId));
            assertEq(proxyAdmin.owner(), newOwner, "new owner not set correctly");
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
