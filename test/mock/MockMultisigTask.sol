// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {IProxy} from "@eth-optimism-bedrock/interfaces/universal/IProxy.sol";

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

/// Mock task that upgrades the L1ERC721BridgeProxy implementation
/// to an example implementation address
contract MockMultisigTask is MultisigTask {
    address public constant newImplementation = address(1000);

    /// @notice Returns the safe address string identifier
    /// @return The string "SystemConfigOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "L1ERC721BridgeProxy";
        return storageWrites;
    }

    // no-op
    function _templateSetup(string memory) internal override {}

    function _build(uint256 chainId) internal override {
        IProxyAdmin proxy = IProxyAdmin(payable(addresses.getAddress("ProxyAdmin", chainId)));

        proxy.upgrade(
            payable(addresses.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId)), newImplementation
        );
    }

    function _validate(uint256 chainId) internal view override {
        IProxy proxy = IProxy(payable(addresses.getAddress("L1ERC721BridgeProxy", chainId)));
        bytes32 IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 data = vm.load(address(proxy), IMPLEMENTATION_SLOT);

        assertEq(bytes32(uint256(uint160(newImplementation))), data, "Proxy implementation not set correctly");
    }

    function addAction(address target, bytes memory data, uint256 value, string memory description) public {
        actions.push(Action(target, value, data, description));
    }
}
