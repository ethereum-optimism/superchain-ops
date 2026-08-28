// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {console} from "forge-std/console.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {StorageSetter} from "@eth-optimism-bedrock/src/universal/StorageSetter.sol";

/// @notice Template contract for doing a batch transfer of ownership for one or more chains.
/// This includes the L1ProxyAdminOwner, DisputeGameFactory and optionally the Permissioned/Permissionless DelayedWETH contracts.
/// Some chains may not have a PermissionedWETH or PermissionlessWETH and or may not be ownable. We handle this accordingly.
/// All chains in the task must currently be owned by the same ProxyAdminOwner safe and are transferred to the same new owner.
/// ATTENTION: Please use caution when using this template. Transferring ownership is high risk.
contract TransferOwners is L2TaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice New owner address. This is unaliased.
    address internal newOwner;

    /// @notice Stores the chain information for all chains in the task after setup.
    /// We must snapshot this list before `_validateSuperchainConfig` runs because that
    /// function discovers the OP Mainnet/OP Sepolia chain into the registry, and iterating
    /// `superchainAddrRegistry.getChains()` afterwards would include it in the transfer set.
    SuperchainAddressRegistry.ChainInfo[] internal taskChains;

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
    function _templateSetup(string memory _taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, rootSafe);
        string memory toml = vm.readFile(_taskConfigFilePath);
        newOwner = toml.readAddress(".newOwner");

        SuperchainAddressRegistry.ChainInfo[] memory _parsedChains = superchainAddrRegistry.getChains();
        require(_parsedChains.length > 0, "Must specify at least one chain id to transfer ownership for");
        for (uint256 i = 0; i < _parsedChains.length; i++) {
            taskChains.push(_parsedChains[i]);
        }

        // Discover OP Mainnet or OP Sepolia to get access to the latest SuperchainConfig address.
        // We assume that these chains are always using the standard config.
        address expectedSuperchainConfig = _discoverExpectedSuperchainConfig();

        for (uint256 i = 0; i < taskChains.length; i++) {
            // The discovered SuperchainConfig address must match the SuperchainConfig address in the standard config.
            address superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", taskChains[i].chainId);
            require(
                superchainConfig == expectedSuperchainConfig,
                string.concat("SuperchainConfig mismatch for chain ", taskChains[i].name)
            );
        }
    }

    /// @notice Builds the actions for transferring ownership of the DisputeGameFactory, DWETH contracts and ProxyAdmin
    /// for each chain in the task.
    function _build(address) internal override {
        for (uint256 i = 0; i < taskChains.length; i++) {
            _buildForChain(taskChains[i]);
        }
    }

    /// @notice Builds the ownership transfer actions for a single chain.
    function _buildForChain(SuperchainAddressRegistry.ChainInfo memory chain) internal {
        IProxyAdmin proxyAdmin = IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chain.chainId));
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chain.chainId));
        IDelayedWETH permissionedWETH = _getDWETH("PermissionedWETH", chain.chainId);
        IDelayedWETH permissionlessWETH = _getDWETH("PermissionlessWETH", chain.chainId);

        // Transfer ownership of the DisputeGameFactory to the new owner.
        performOwnershipTransfer(address(disputeGameFactory), newOwner);

        // Check if PermissionedWETH exists and is ownable. If it is, transfer ownership to the new owner.
        if (address(permissionedWETH) != address(0)) {
            performTransferIfOwnable(proxyAdmin, address(permissionedWETH), newOwner);
        } else {
            console.log("PermissionedWETH not found or not ownable on chain %s, not performing transfer", chain.chainId);
        }

        // Check if PermissionlessWETH exists and is ownable. If it is, transfer ownership to the new owner.
        if (address(permissionlessWETH) != address(0)) {
            performTransferIfOwnable(proxyAdmin, address(permissionlessWETH), newOwner);
        } else {
            console.log(
                "PermissionlessWETH not found or not ownable on chain %s, not performing transfer", chain.chainId
            );
        }

        // Transfer ownership of the ProxyAdmin to the new owner. This must be performed last for each chain
        // because the DelayedWETH transfers above require the root safe to still own the ProxyAdmin.
        performOwnershipTransfer(address(proxyAdmin), newOwner);
    }

    /// @notice Validates that the owner was transferred correctly for each chain.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        for (uint256 i = 0; i < taskChains.length; i++) {
            SuperchainAddressRegistry.ChainInfo memory chain = taskChains[i];
            IProxyAdmin proxyAdmin = IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chain.chainId));
            IDisputeGameFactory disputeGameFactory =
                IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chain.chainId));
            IDelayedWETH permissionedWETH = _getDWETH("PermissionedWETH", chain.chainId);
            IDelayedWETH permissionlessWETH = _getDWETH("PermissionlessWETH", chain.chainId);
            assertEq(disputeGameFactory.owner(), newOwner, "new owner not set correctly on DisputeGameFactory");
            assertEq(proxyAdmin.owner(), newOwner, "new owner not set correctly on ProxyAdmin");

            // Check if the PermissionedWETH is ownable and if it is, check if the owner is set correctly.
            if (address(permissionedWETH) != address(0) && _isDWETHOwnable(permissionedWETH)) {
                assertEq(permissionedWETH.owner(), newOwner, "new owner not set correctly on PermissionedWETH");
            }

            // Check if the PermissionlessWETH is ownable and if it is, check if the owner is set correctly.
            if (address(permissionlessWETH) != address(0) && _isDWETHOwnable(permissionlessWETH)) {
                assertEq(permissionlessWETH.owner(), newOwner, "new owner not set correctly on PermissionlessWETH");
            }
        }
    }

    /// @notice Gets the DWETH contract address for the given chain id. Trying to call the superchain address registry
    /// with a key that does not exist will normally revert. We handle this gracefully and return address(0) because we
    /// want to proceed and not error.
    function _getDWETH(string memory _key, uint256 _chainId) internal view returns (IDelayedWETH) {
        (bool success, bytes memory data) = address(superchainAddrRegistry).staticcall(
            abi.encodeCall(SuperchainAddressRegistry.getAddress, (_key, _chainId))
        );
        return success ? abi.decode(data, (IDelayedWETH)) : IDelayedWETH(address(0));
    }

    /// @notice Checks if the given DWETH is ownable. Post U16 DWETHs are not ownable and therefore we should not attempt
    /// to transfer ownership of them. Post U16 DWETHs no longer have an `owner()` function, and the unknown selector is
    /// swallowed by the WETH98 fallback which returns successfully with empty data, so we must also check the return
    /// data length before decoding.
    function _isDWETHOwnable(IDelayedWETH _dweth) internal view returns (bool) {
        (bool success, bytes memory data) = address(_dweth).staticcall(abi.encodeCall(IOwnable.owner, ()));
        return success && data.length == 32 ? abi.decode(data, (address)) != address(0) : false;
    }

    /// @notice Performs an ownership transfer for the given target. If the target is address(0) we will not perform
    /// the transfer.
    function performOwnershipTransfer(address _target, address _newOwner) internal {
        IOwnable(_target).transferOwnership(_newOwner);
    }

    /// @notice If the target is Ownable, performs an ownership transfer by writing the new owner
    /// directly to the owner slot.
    function performTransferIfOwnable(IProxyAdmin _proxyAdmin, address _target, address _newOwner) internal {
        if (_isDWETHOwnable(IDelayedWETH(_target))) {
            _writeToProxy(_proxyAdmin, _target, bytes32(uint256(51)), bytes32(uint256(uint160(_newOwner))));
        } else {
            console.log("Target is not ownable, not performing transfer");
        }
    }

    /// @notice Writes a value to a proxy contract.
    /// @dev This is accomplished by upgrading the proxy to the StorageSetter, writing the value,
    /// and then upgrading the proxy back to the previous implementation.
    /// @param proxyAdmin The ProxyAdmin that administers the proxy.
    /// @param proxy The address of the proxy contract.
    /// @param slot The slot to write to.
    /// @param value The value to write.
    function _writeToProxy(IProxyAdmin proxyAdmin, address proxy, bytes32 slot, bytes32 value) internal {
        address storageSetter = 0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC;

        // Upgrade the proxy to the StorageSetter.
        address implBefore = proxyAdmin.getProxyImplementation(proxy);
        proxyAdmin.upgrade(payable(proxy), storageSetter);

        StorageSetter(proxy).setBytes32(slot, value);
        proxyAdmin.upgrade(payable(proxy), implBefore);
    }

    /// @notice Gets the chain info for the given chain name.
    function getChainInfo(string memory _chainName) internal returns (SuperchainAddressRegistry.ChainInfo memory) {
        return SuperchainAddressRegistry.ChainInfo({chainId: getChain(_chainName).chainId, name: _chainName});
    }

    /// @notice Discovers the OP Mainnet or OP Sepolia chain and returns its SuperchainConfig address.
    function _discoverExpectedSuperchainConfig() internal returns (address) {
        // 'block.chainId' will be set to whatever the network the current rpc url is pointing to.
        SuperchainAddressRegistry.ChainInfo memory chainInfo;
        if (block.chainid == getChain("mainnet").chainId) {
            chainInfo = getChainInfo("optimism");
        } else if (block.chainid == getChain("sepolia").chainId) {
            chainInfo = getChainInfo("optimism_sepolia");
        } else {
            revert("Unsupported chain id");
        }

        superchainAddrRegistry.discoverNewChain(chainInfo);
        return superchainAddrRegistry.getAddress("SuperchainConfig", chainInfo.chainId);
    }

    /// @notice no code exceptions for this template
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface IOwnable {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

interface IDisputeGameFactory {
    function owner() external view returns (address);
}

interface IDelayedWETH {
    function owner() external view returns (address);
}
