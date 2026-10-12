// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface IOptimismPortal2 {
    function setProofMaturityDelaySeconds(uint256 _proofMaturityDelaySeconds) external;
    function proofMaturityDelaySeconds() external view returns (uint256);
    function minProofMaturityDelaySeconds() external view returns (uint256);
    function maxProofMaturityDelaySeconds() external view returns (uint256);
    function ethLockbox() external view returns (address);
}

interface IAnchorStateRegistry {
    function setDisputeGameFinalityDelaySeconds(uint256 _disputeGameFinalityDelaySeconds) external;
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function minDisputeGameFinalityDelaySeconds() external view returns (uint256);
    function maxDisputeGameFinalityDelaySeconds() external view returns (uint256);
}

interface IDelayedWETH {
    function setDelay(uint256 _delay) external;
    function delay() external view returns (uint256);
    function minDelay() external view returns (uint256);
    function maxDelay() external view returns (uint256);
}

interface ISystemConfig {
    function delayedWETH() external view returns (address);
}

/// @notice Sets the withdrawal review period delays of every chain in the task in one transaction:
/// `OptimismPortal2.setProofMaturityDelaySeconds` on each chain's portal, and
/// `AnchorStateRegistry.setDisputeGameFinalityDelaySeconds` / `DelayedWETH.setDelay` on the chain's
/// AnchorStateRegistry and DelayedWETH, which the chains of an interop set share.
///
/// Every `[delays]` key is optional and one value applies to all chains in the task. A setter is only
/// called where the on-chain value differs, and a shared contract is called once. All three setters
/// are restricted to the ProxyAdminOwner.
///
/// List every chain of an interop set in the same task: shared contracts are then written once and the
/// proof maturity uniformity check in `_validate` sees all members.
/// Supports: OptimismPortal2 >= 6.0.0, AnchorStateRegistry >= 5.0.0, DelayedWETH >= 3.0.0.
contract SetReviewPeriodDelays is L2TaskBase {
    using stdToml for string;

    /// @notice Delays read from `[delays]`. A `set*` flag is false when its key is absent.
    struct Delays {
        uint256 proofMaturityDelaySeconds;
        uint256 disputeGameFinalityDelaySeconds;
        uint256 withdrawalDelaySeconds;
        bool setProofMaturity;
        bool setFinalityDelay;
        bool setWithdrawalDelay;
    }

    /// @notice Configuration for the task. One value applies to every chain.
    Delays public cfg;

    /// @notice Targets whose on-chain value differs from the configured one. A contract shared by
    /// several chains in the task appears once, since the task framework rejects duplicate actions.
    address[] public portalsToSet;
    address[] public asrsToSet;
    address[] public wethsToSet;

    /// @notice Returns the safe address string identifier. All three setters are ProxyAdminOwner-only.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    /// `DelayedWETH` is registered in `_templateSetup` from `SystemConfig.delayedWETH()`.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](3);
        storageWrites[0] = "OptimismPortalProxy";
        storageWrites[1] = "AnchorStateRegistryProxy";
        storageWrites[2] = "DelayedWETH";
        return storageWrites;
    }

    /// @notice Reads `[delays]`, checks each configured value against the contract's bounds and collects
    /// the targets whose on-chain value differs.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);

        cfg = _parseDelays(vm.readFile(_taskConfigFilePath));
        require(
            cfg.setProofMaturity || cfg.setFinalityDelay || cfg.setWithdrawalDelay,
            "SetReviewPeriodDelays: no key set under [delays]"
        );

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            // SystemConfig.delayedWETH() is the canonical DelayedWETH pointer (StandardValidator DWETH-70).
            // The registry has no key for it, so register one to allow-list its storage writes.
            address weth = ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)).delayedWETH();
            if (weth != address(0)) {
                superchainAddrRegistry.saveAddress("DelayedWETH", chains[i], weth);
            }

            if (cfg.setProofMaturity) {
                IOptimismPortal2 portal = _portal(chainId);
                _requireInBounds(
                    cfg.proofMaturityDelaySeconds,
                    portal.minProofMaturityDelaySeconds(),
                    portal.maxProofMaturityDelaySeconds(),
                    "proofMaturityDelaySeconds"
                );
                if (portal.proofMaturityDelaySeconds() != cfg.proofMaturityDelaySeconds) {
                    _pushUnique(portalsToSet, address(portal));
                }
            }

            if (cfg.setFinalityDelay) {
                IAnchorStateRegistry asr = _asr(chainId);
                _requireInBounds(
                    cfg.disputeGameFinalityDelaySeconds,
                    asr.minDisputeGameFinalityDelaySeconds(),
                    asr.maxDisputeGameFinalityDelaySeconds(),
                    "disputeGameFinalityDelaySeconds"
                );
                // Chains of the interop set resolve to the same ASR, so it is collected once and called once.
                if (asr.disputeGameFinalityDelaySeconds() != cfg.disputeGameFinalityDelaySeconds) {
                    _pushUnique(asrsToSet, address(asr));
                }
            }

            if (cfg.setWithdrawalDelay) {
                require(weth != address(0), "SetReviewPeriodDelays: SystemConfig.delayedWETH() is zero");
                _requireInBounds(
                    cfg.withdrawalDelaySeconds,
                    IDelayedWETH(weth).minDelay(),
                    IDelayedWETH(weth).maxDelay(),
                    "withdrawalDelaySeconds"
                );
                // Chains of the interop set share one DelayedWETH, so it is collected once and called once.
                if (IDelayedWETH(weth).delay() != cfg.withdrawalDelaySeconds) {
                    _pushUnique(wethsToSet, weth);
                }
            }
        }

        require(
            portalsToSet.length + asrsToSet.length + wethsToSet.length > 0,
            "SetReviewPeriodDelays: no-op (all configured delays already match on-chain values)"
        );
    }

    /// @notice Calls each setter once per target whose value changes.
    function _build(address) internal override {
        for (uint256 i = 0; i < portalsToSet.length; i++) {
            IOptimismPortal2(portalsToSet[i]).setProofMaturityDelaySeconds(cfg.proofMaturityDelaySeconds);
        }
        for (uint256 i = 0; i < asrsToSet.length; i++) {
            IAnchorStateRegistry(asrsToSet[i]).setDisputeGameFinalityDelaySeconds(cfg.disputeGameFinalityDelaySeconds);
        }
        for (uint256 i = 0; i < wethsToSet.length; i++) {
            IDelayedWETH(wethsToSet[i]).setDelay(cfg.withdrawalDelaySeconds);
        }
    }

    /// @notice Asserts that every configured delay reads back on every chain in the task.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            if (cfg.setProofMaturity) {
                require(
                    _portal(chainId).proofMaturityDelaySeconds() == cfg.proofMaturityDelaySeconds,
                    "SetReviewPeriodDelays: proofMaturityDelaySeconds mismatch"
                );
            }
            if (cfg.setFinalityDelay) {
                require(
                    _asr(chainId).disputeGameFinalityDelaySeconds() == cfg.disputeGameFinalityDelaySeconds,
                    "SetReviewPeriodDelays: disputeGameFinalityDelaySeconds mismatch"
                );
            }
            if (cfg.setWithdrawalDelay) {
                require(
                    _weth(chainId).delay() == cfg.withdrawalDelaySeconds,
                    "SetReviewPeriodDelays: withdrawalDelaySeconds mismatch"
                );
            }
        }

        _checkSetUniformity(chains);
    }

    /// @notice POLICY (unconfirmed): portals that share an ETHLockbox form one interop set and must carry
    /// the same proof maturity delay, because the pooled liquidity exits after the shortest one.
    /// Only the chains in the task are visible, since set membership is not enumerable on-chain, so the
    /// task must list every chain of the set. Delete this function and its call to drop the check.
    function _checkSetUniformity(SuperchainAddressRegistry.ChainInfo[] memory chains) internal view {
        for (uint256 i = 0; i < chains.length; i++) {
            IOptimismPortal2 portalA = _portal(chains[i].chainId);
            address lockbox = portalA.ethLockbox();
            if (lockbox == address(0)) continue;
            for (uint256 j = i + 1; j < chains.length; j++) {
                IOptimismPortal2 portalB = _portal(chains[j].chainId);
                if (portalB.ethLockbox() != lockbox) continue;
                require(
                    portalA.proofMaturityDelaySeconds() == portalB.proofMaturityDelaySeconds(),
                    "SetReviewPeriodDelays: portals in the same set have different proofMaturityDelaySeconds"
                );
            }
        }
    }

    /// @notice Reads `[delays]`. Every key is optional; an absent key leaves that delay untouched.
    function _parseDelays(string memory tomlContent) internal view returns (Delays memory delays) {
        delays.setProofMaturity = tomlContent.keyExists(".delays.proofMaturityDelaySeconds");
        delays.setFinalityDelay = tomlContent.keyExists(".delays.disputeGameFinalityDelaySeconds");
        delays.setWithdrawalDelay = tomlContent.keyExists(".delays.withdrawalDelaySeconds");
        if (delays.setProofMaturity) {
            delays.proofMaturityDelaySeconds = tomlContent.readUint(".delays.proofMaturityDelaySeconds");
        }
        if (delays.setFinalityDelay) {
            delays.disputeGameFinalityDelaySeconds = tomlContent.readUint(".delays.disputeGameFinalityDelaySeconds");
        }
        if (delays.setWithdrawalDelay) {
            delays.withdrawalDelaySeconds = tomlContent.readUint(".delays.withdrawalDelaySeconds");
        }
    }

    /// @notice Checks that the desired delay falls within configured bounds.
    /// Fails at setup, with a readable message, instead of inside the Safe simulation where the
    /// contract's custom error is not surfaced.
    function _requireInBounds(uint256 value, uint256 min, uint256 max, string memory name) internal pure {
        require(
            value >= min && value <= max,
            string.concat("SetReviewPeriodDelays: ", name, " outside the contract's [min, max]")
        );
    }

    /// @notice Appends `addr` to `list` unless it is already present.
    function _pushUnique(address[] storage list, address addr) internal {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == addr) return;
        }
        list.push(addr);
    }

    function _portal(uint256 _chainId) internal view returns (IOptimismPortal2) {
        return IOptimismPortal2(superchainAddrRegistry.getAddress("OptimismPortalProxy", _chainId));
    }

    function _asr(uint256 _chainId) internal view returns (IAnchorStateRegistry) {
        return IAnchorStateRegistry(superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", _chainId));
    }

    function _weth(uint256 _chainId) internal view returns (IDelayedWETH) {
        return IDelayedWETH(superchainAddrRegistry.getAddress("DelayedWETH", _chainId));
    }

    /// @notice No EOAs are written to, so there are no code exceptions.
    function _getCodeExceptions() internal pure override returns (address[] memory) {}
}
