// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {LibString} from "solady/utils/LibString.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

/// @notice Template contract for doing a batch transfer of ownership for a chain.
/// This includes the L1ProxyAdminOwner, DisputeGameFactory and Permissioned/Permissionless DelayedWETH contracts.
/// Some chains may not have a PermissionedWETH or PermissionlessWETH so we handle this accordingly.
/// ATTENTION: Please use caution when using this template. Transferring ownership is high risk.
contract TransferOwners is L2TaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice New owner address. This is unaliased.
    address public newOwner;

    /// @notice StorageSetter address.
    address public STORAGE_SETTER;

    /// @notice PermissionedDWETH address.
    address public permissionedWETH;

    /// @notice PermissionlessDWETH address.
    address public permissionlessWETH;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](4);
        storageWrites[0] = "DisputeGameFactoryProxy";
        storageWrites[1] = "ProxyAdmin";
        storageWrites[2] = "PermissionedWETH";
        storageWrites[3] = "PermissionlessWETH";
        return storageWrites;
    }

    /// @notice Sets up the template with the new owner from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory toml = vm.readFile(taskConfigFilePath);
        newOwner = abi.decode(vm.parseToml(toml, ".newOwner"), (address));

        // Only allow one chain to be modified at a time with this template.
        SuperchainAddressRegistry.ChainInfo[] memory _chains =
            abi.decode(vm.parseToml(toml, ".l2chains"), (SuperchainAddressRegistry.ChainInfo[]));
        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");

        STORAGE_SETTER = abi.decode(vm.parseToml(toml, ".addresses.StorageSetter"), (address));
        require(address(STORAGE_SETTER).code.length > 0, "Incorrect StorageSetter - no code at address");
        require(StorageSetter(STORAGE_SETTER).version().eq("1.1.0"), "Incorrect StorageSetter version");
    }

    /// @notice Builds the actions for transferring ownership of the DisputeGameFactory, DWETH contracts and ProxyAdmin.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        uint256 chainId = chains[0].chainId;
        ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chainId));
        address dgfProxy = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
        permissionedWETH = _getDWETH("PermissionedWETH", chainId);
        permissionlessWETH = _getDWETH("PermissionlessWETH", chainId);

        // Get the current implementation of the DisputeGameFactory before the storage setter is set.
        address originalDGFImpl = getEIP1967Impl(dgfProxy);
        // Set initialized slot to zero.
        setInitializedToZero(proxyAdmin, dgfProxy);
        // Reinitialize the DisputeGameFactory with the new owner.
        proxyAdmin.upgradeAndCall(
            payable(dgfProxy), originalDGFImpl, abi.encodeCall(DisputeGameFactory.initialize, (newOwner))
        );

        // Transfer ownership of the PermissionedWETH to the new owner.
        _upgradeDWETH(proxyAdmin, permissionedWETH, newOwner);
        // Transfer ownership of the PermissionlessWETH to the new owner.
        _upgradeDWETH(proxyAdmin, permissionlessWETH, newOwner);
        // Transfer ownership of the ProxyAdmin to the new owner. This must be performed last.
        proxyAdmin.transferOwnership(newOwner);
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[0].chainId));
        DisputeGameFactory dgfProxy =
            DisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chains[0].chainId));
        assertEq(dgfProxy.owner(), newOwner, "new owner not set correctly on DisputeGameFactory");
        assertEq(proxyAdmin.owner(), newOwner, "new owner not set correctly on ProxyAdmin");

        if (permissionedWETH != address(0)) {
            assertEq(DelayedWETH(permissionedWETH).owner(), newOwner, "new owner not set correctly on PermissionedWETH");
        }

        if (permissionlessWETH != address(0)) {
            DelayedWETH permissionlessWETHProxy = DelayedWETH(permissionlessWETH);
            assertEq(permissionlessWETHProxy.owner(), newOwner, "new owner not set correctly on PermissionlessWETH");
        }
    }

    /// @notice Sets the initialized slot to zero for the given proxy using the StorageSetter contract.
    function setInitializedToZero(ProxyAdmin _proxyAdmin, address _proxy) internal {
        bytes32 ZERO = bytes32(uint256(0));
        _proxyAdmin.upgradeAndCall(
            payable(_proxy), STORAGE_SETTER, abi.encodeCall(StorageSetter.setBytes32, (ZERO, ZERO))
        );
    }

    /// @notice Gets the EIP1967 implementation address for the given proxy.
    function getEIP1967Impl(address _proxy) internal view returns (address impl_) {
        impl_ = address(uint160(uint256((vm.load(_proxy, Constants.PROXY_IMPLEMENTATION_ADDRESS)))));
    }

    /// @notice Gets the DWETH contract address for the given chain id. Trying to call the superchain address registry
    /// with a key that does not exist will normally revert. We handle this gracefully and return address(0) because we
    /// want to proceed and not error.
    function _getDWETH(string memory _key, uint256 _chainId) internal returns (address) {
        (bool success, bytes memory data) =
            address(superchainAddrRegistry).call(abi.encodeCall(SuperchainAddressRegistry.getAddress, (_key, _chainId)));
        return success ? abi.decode(data, (address)) : address(0);
    }

    /// @notice Upgrades the DWETH contract and sets the owner to the new owner.
    function _upgradeDWETH(ProxyAdmin _proxyAdmin, address _dweth, address _newOwner) internal {
        if (_dweth != address(0)) {
            address superchainConfig = DelayedWETH(_dweth).config();
            address originalImpl = getEIP1967Impl(_dweth);
            setInitializedToZero(_proxyAdmin, _dweth);
            _proxyAdmin.upgradeAndCall(
                payable(_dweth), originalImpl, abi.encodeCall(DelayedWETH.initialize, (_newOwner, superchainConfig))
            );
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface StorageSetter {
    function version() external view returns (string memory);
    function setBytes32(bytes32 _slot, bytes32 _value) external;
}

interface ProxyEIP1967 {
    function implementation() external view returns (address);
}

interface DisputeGameFactory {
    function initialize(address _owner) external;
    function owner() external view returns (address);
}

interface DelayedWETH {
    function config() external view returns (address);
    function initialize(address _owner, address _config) external;
    function owner() external view returns (address);
}
