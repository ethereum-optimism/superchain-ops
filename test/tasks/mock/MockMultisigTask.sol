// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {IProxy} from "@eth-optimism-bedrock/interfaces/universal/IProxy.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MockTarget} from "test/tasks/mock/MockTarget.sol";

/// Mock task that upgrades the L1ERC721BridgeProxy implementation
/// to an example implementation address
contract MockMultisigTask is L2TaskBase {
    address public constant newImplementation = address(1000);

    /// @notice reference to the mock target contract
    MockTarget public mockTarget;

    /// @notice Returns the safe address string identifier
    /// @return The string "SystemConfigOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "L1ERC721BridgeProxy";
        storageWrites[1] = "ProxyAdminOwner";
        return storageWrites;
    }

    function _templateSetup(string memory) internal override {
        super._templateSetup("");
    }

    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            IProxyAdmin proxy = IProxyAdmin(payable(superchainAddrRegistry.getAddress("ProxyAdmin", chainId)));

            proxy.upgrade(
                payable(superchainAddrRegistry.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId)),
                newImplementation
            );

            if (address(mockTarget) != address(0)) {
                // set the snapshot ID for the MockTarget contract if the address is set
                mockTarget.setSnapshotIdTask(18291864375436131);
            }
        }
    }

    /// @notice Validates that the proxy implementation was set correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            IProxy proxy = IProxy(payable(superchainAddrRegistry.getAddress("L1ERC721BridgeProxy", chainId)));
            bytes32 data = vm.load(address(proxy), Constants.PROXY_IMPLEMENTATION_ADDRESS);
            assertEq(bytes32(uint256(uint160(newImplementation))), data, "Proxy implementation not set correctly");
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}

    /// @notice Wrapper function to call the internal _isValidAction function. This is used to test the internal function.
    function wrapperIsValidAction(VmSafe.AccountAccess memory access, uint256 topLevelDepth)
        public
        view
        returns (bool isValid)
    {
        return super._isValidAction(access, topLevelDepth);
    }
}
