// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {console} from "forge-std/console.sol";

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

    /// @notice PermissionedWETH address.
    address public permissionedWETH;

    /// @notice PermissionlessWETH address.
    address public permissionlessWETH;

    /// @notice Stores the chain information after setup.
    SuperchainAddressRegistry.ChainInfo internal activeChainInfo;

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
    function _templateSetup(string memory _taskConfigFilePath) internal override {
        super._templateSetup(_taskConfigFilePath);
        string memory toml = vm.readFile(_taskConfigFilePath);
        newOwner = abi.decode(vm.parseToml(toml, ".newOwner"), (address));

        // Only allow one chain to be modified at a time with this template.
        SuperchainAddressRegistry.ChainInfo[] memory _parsedChains =
            abi.decode(vm.parseToml(toml, ".l2chains"), (SuperchainAddressRegistry.ChainInfo[]));
        require(_parsedChains.length == 1, "Must specify exactly one chain id to transfer ownership for");
        activeChainInfo = _parsedChains[0]; // Store the ChainInfo struct
    }

    /// @notice Builds the actions for transferring ownership of the DisputeGameFactory, DWETH contracts and ProxyAdmin.
    function _build() internal override {
        ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", activeChainInfo.chainId));
        address dgfProxy = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", activeChainInfo.chainId);
        permissionedWETH = _getDWETH("PermissionedWETH", activeChainInfo.chainId);
        permissionlessWETH = _getDWETH("PermissionlessWETH", activeChainInfo.chainId);

        // Transfer ownership of the DisputeGameFactory to the new owner.
        performOwnershipTransfer(dgfProxy, newOwner);

        // Transfer ownership of the PermissionedWETH to the new owner.
        if (permissionedWETH != address(0)) {
            performOwnershipTransfer(permissionedWETH, newOwner);
        } else {
            console.log("PermissionedWETH not found on chain %s not performing transfer", activeChainInfo.chainId);
        }

        // Transfer ownership of the PermissionlessWETH to the new owner.
        if (permissionlessWETH != address(0)) {
            performOwnershipTransfer(permissionlessWETH, newOwner);
        } else {
            console.log("PermissionlessWETH not found on chain %s not performing transfer", activeChainInfo.chainId);
        }

        // Transfer ownership of the ProxyAdmin to the new owner. This must be performed last.
        performOwnershipTransfer(address(proxyAdmin), newOwner);
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", activeChainInfo.chainId));
        DisputeGameFactory dgfProxy =
            DisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", activeChainInfo.chainId));
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

    /// @notice Gets the DWETH contract address for the given chain id. Trying to call the superchain address registry
    /// with a key that does not exist will normally revert. We handle this gracefully and return address(0) because we
    /// want to proceed and not error.
    function _getDWETH(string memory _key, uint256 _chainId) internal returns (address) {
        (bool success, bytes memory data) =
            address(superchainAddrRegistry).call(abi.encodeCall(SuperchainAddressRegistry.getAddress, (_key, _chainId)));
        return success ? abi.decode(data, (address)) : address(0);
    }

    /// @notice Performs an ownership transfer for the given target. If the target is address(0) we will not perform
    /// the transfer.
    function performOwnershipTransfer(address _target, address _newOwner) internal {
        if (_target == address(0)) return;
        Ownable(_target).transferOwnership(_newOwner);
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface Ownable {
    function transferOwnership(address newOwner) external;
}

interface DisputeGameFactory {
    function owner() external view returns (address);
}

interface DelayedWETH {
    function owner() external view returns (address);
}
