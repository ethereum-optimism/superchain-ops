// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

/// @notice Template contract for doing a batch transfer of ownership for a chain.
/// This includes the L1ProxyAdminOwner, DisputeGameFactory and Permissioned/Permissionless DelayedWETH contracts.
/// ATTENTION: Please use caution when using this template. Transferring ownership is high risk.
contract TransferOwners is L2TaskBase {
    using stdToml for string;

    /// @notice New owner address. This is unaliased.
    address public newOwner;

    /// @notice StorageSetter implementation address.
    address public constant STORAGE_SETTER = 0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "DisputeGameFactoryProxy";
        storageWrites[1] = "ProxyAdmin";
        return storageWrites;
    }

    /// @notice Sets up the template with the new owner from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory toml = vm.readFile(taskConfigFilePath);
        newOwner = abi.decode(vm.parseToml(toml, ".newOwner"), (address));

        // only allow one chain to be modified at a time with this template
        SuperchainAddressRegistry.ChainInfo[] memory _chains =
            abi.decode(vm.parseToml(toml, ".l2chains"), (SuperchainAddressRegistry.ChainInfo[]));

        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");
    }

    /// @notice Builds the actions for transferring ownership of the DisputeGameFactory, DWETH contracts and ProxyAdmin.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        bytes32 ZERO_BYTES32 = bytes32(uint256(0));

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chainId));
            address dgfProxy = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            address currentImpl = getCurrentDisputeGameFactoryImpl(dgfProxy);

            // Set initialized slot to zero.
            proxyAdmin.upgradeAndCall(
                payable(dgfProxy),
                STORAGE_SETTER,
                abi.encodeWithSelector(StorageSetter.setBytes32.selector, ZERO_BYTES32, ZERO_BYTES32)
            );
            // Reinitialize the DisputeGameFactory with the new owner.
            proxyAdmin.upgradeAndCall(
                payable(dgfProxy), currentImpl, abi.encodeWithSelector(DisputeGameFactory.initialize.selector, newOwner)
            );

            // TODO: Transfer ownership for DWETH contracts.

            // Transfer ownership of the ProxyAdmin to the new owner.
            proxyAdmin.transferOwnership(newOwner);
        }
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[i].chainId));
            DisputeGameFactory dgfProxy =
                DisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chains[i].chainId));
            assertEq(dgfProxy.owner(), newOwner, "new owner not set correctly on DisputeGameFactory");
            assertEq(proxyAdmin.owner(), newOwner, "new owner not set correctly on ProxyAdmin");
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}

    function getCurrentDisputeGameFactoryImpl(address disputeGameFactory) internal view returns (address impl_) {
        impl_ = address(uint160(uint256((vm.load(disputeGameFactory, Constants.PROXY_IMPLEMENTATION_ADDRESS)))));
    }
}

interface StorageSetter {
    function setBytes32(bytes32 _slot, bytes32 _value) external;
}

interface ProxyEIP1967 {
    function implementation() external view returns (address);
}

interface DisputeGameFactory {
    function initialize(address _owner) external;
    function owner() external view returns (address);
}
