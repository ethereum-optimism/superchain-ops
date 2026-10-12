// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface IDelayedWETH {
    function setDelay(uint256 _delay) external;
    function delay() external view returns (uint256);
    function minDelay() external view returns (uint256);
    function maxDelay() external view returns (uint256);
}

interface ISystemConfig {
    function delayedWETH() external view returns (address);
}

/// @notice Sets the DelayedWETH bond lockup (`delay`) for every chain in the task via
/// `DelayedWETH.setDelay`, which is restricted to the ProxyAdminOwner. The DelayedWETH is read from
/// `SystemConfig.delayedWETH()`; chains of an interop set share one, which is written once.
/// Supports: DelayedWETH >= 3.0.0.
contract SetDelayedWETHDelay is L2TaskBase {
    using stdToml for string;

    /// @notice The delay to set, in seconds. One value applies to every chain in the task.
    uint256 public delaySeconds;

    /// @notice DelayedWETH contracts to write, each once, since the task framework rejects duplicate actions.
    address[] public delayedWETHs;

    /// @notice Returns the safe address string identifier. `setDelay` is ProxyAdminOwner-only.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    /// `DelayedWETH` is registered in `_templateSetup` from `SystemConfig.delayedWETH()`.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DelayedWETH";
        return storageWrites;
    }

    /// @notice Reads the delay from `[delayedWETH]` and resolves each chain's DelayedWETH.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);

        delaySeconds = vm.readFile(_taskConfigFilePath).readUint(".delayedWETH.delaySeconds");

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            // SystemConfig.delayedWETH() is the canonical DelayedWETH pointer (StandardValidator DWETH-70).
            // The registry has no key for it, so register one to allow-list its storage writes.
            address weth = ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)).delayedWETH();
            require(weth != address(0), "SetDelayedWETHDelay: SystemConfig.delayedWETH() is zero");
            superchainAddrRegistry.saveAddress("DelayedWETH", chains[i], weth);

            // Fails here with a readable message instead of inside the Safe simulation.
            require(
                delaySeconds >= IDelayedWETH(weth).minDelay() && delaySeconds <= IDelayedWETH(weth).maxDelay(),
                "SetDelayedWETHDelay: delaySeconds outside the contract's [min, max]"
            );
            _pushUnique(delayedWETHs, weth);
        }
    }

    /// @notice Sets the delay on each DelayedWETH once.
    function _build(address) internal override {
        for (uint256 i = 0; i < delayedWETHs.length; i++) {
            IDelayedWETH(delayedWETHs[i]).setDelay(delaySeconds);
        }
    }

    /// @notice Asserts that the delay reads back on every chain in the task.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            IDelayedWETH weth = IDelayedWETH(superchainAddrRegistry.getAddress("DelayedWETH", chains[i].chainId));
            require(weth.delay() == delaySeconds, "SetDelayedWETHDelay: delay mismatch");
        }
    }

    /// @notice Appends `addr` to `list` unless it is already present.
    function _pushUnique(address[] storage list, address addr) internal {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == addr) return;
        }
        list.push(addr);
    }

    /// @notice No EOAs are written to, so there are no code exceptions.
    function _getCodeExceptions() internal pure override returns (address[] memory) {}
}
