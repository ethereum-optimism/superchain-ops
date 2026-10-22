// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {SemverComp} from "src/libraries/SemverComp.sol";

interface IOptimismPortal2 {
    function setProofMaturityDelaySeconds(uint256 _proofMaturityDelaySeconds) external;
    function proofMaturityDelaySeconds() external view returns (uint256);
    function minProofMaturityDelaySeconds() external view returns (uint256);
    function maxProofMaturityDelaySeconds() external view returns (uint256);
    function ethLockbox() external view returns (address);
    function paused() external view returns (bool);
    function version() external view returns (string memory);
}

interface IAnchorStateRegistry {
    function setDisputeGameFinalityDelaySeconds(uint256 _disputeGameFinalityDelaySeconds) external;
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
    function minDisputeGameFinalityDelaySeconds() external view returns (uint256);
    function maxDisputeGameFinalityDelaySeconds() external view returns (uint256);
    function version() external view returns (string memory);
}

interface IDelayedWETH {
    function setDelay(uint256 _delay) external;
    function delay() external view returns (uint256);
    function minDelay() external view returns (uint256);
    function maxDelay() external view returns (uint256);
    function version() external view returns (string memory);
}

interface ISystemConfig {
    function delayedWETH() external view returns (address);
}

/// @notice Sets the withdrawal review period delays of every chain in the task in one transaction:
/// `OptimismPortal2.setProofMaturityDelaySeconds` on each chain's portal, and
/// `AnchorStateRegistry.setDisputeGameFinalityDelaySeconds` / `DelayedWETH.setDelay` on the chain's
/// AnchorStateRegistry and DelayedWETH, which the chains of an interop set share.
///
/// Usage:
/// - Every `[delays]` key is optional and an absent key leaves that delay untouched.
/// - One value applies to all chains in the task.
/// - A setter is only called where the on-chain value differs and a shared interop contract is called once.
/// - List every chain of an interop set in the same task, so shared contracts are written once and the
///   proof maturity uniformity check in `_validate` sees all members.
///
/// Requirements:
/// - The Root safe is the chain's ProxyAdminOwner. All three setters are restricted to it.
/// - Each value must sit within the contract's [min, max] bounds.
/// - No included portal may be paused.
/// - Supported versions: OptimismPortal2 >= 6.0.0, AnchorStateRegistry >= 5.0.0, DelayedWETH >= 3.0.0.
///   Checked at setup for the contracts the configured keys touch.
///
/// Pre-task Verifications:
/// - No portal in the task is paused. The contracts accept a delay change during a pause, but this
///   task refuses it. If a delay is shortened while the chain is paused, withdrawals that were waiting
///   could become finalizable the moment the chain unpauses, which reduces reaction time. The check
///   only runs at simulation time, so recheck the pause state right before execution: a portal paused
///   after signing does not stop the transaction.
/// - No open security alerts exist for any chain in the task when lowering a delay, such as an invalid
///   game in flight. A new delay applies to games that have already resolved and to withdrawals that
///   have already been proven, so lowering it shortens finalization. If an invalid game has
///   resolved and is waiting out the finality delay, a shorter delay gives the guardian less time to
///   blacklist it. This task cannot detect that situation, so manual confirmation is needed.
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

    /// @notice Version of each contract that introduced its setter.
    string internal constant MIN_PORTAL_VERSION = "6.0.0";
    string internal constant MIN_ASR_VERSION = "5.0.0";
    string internal constant MIN_WETH_VERSION = "3.0.0";

    /// @notice Configuration for the task. One value applies to every chain.
    Delays public cfg;

    /// @notice Targets whose on-chain value differs from the configured one. A contract shared by
    /// several chains in the task appears once, since the task framework rejects duplicate actions.
    address[] public portalsToSet;
    address[] public asrsToSet;
    address[] public wethsToSet;

    /// @notice Registry keys of the contracts the configured keys touch, the only ones allowed to be written.
    string[] public storageKeys;

    /// @notice Returns the safe address string identifier. All three setters are ProxyAdminOwner-only.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task, collected in `_templateSetup`.
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        return storageKeys;
    }

    /// @notice Reads `[delays]`, checks each configured value against the contract's version and bounds and
    /// collects the targets whose on-chain value differs. Rejects the task when a portal is paused.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);

        cfg = _parseDelays(vm.readFile(_taskConfigFilePath));
        require(
            cfg.setProofMaturity || cfg.setFinalityDelay || cfg.setWithdrawalDelay,
            "SetReviewPeriodDelays: no key set under [delays]"
        );

        // Register contracts to write depending on flags set in config
        if (cfg.setProofMaturity) storageKeys.push("OptimismPortalProxy");
        if (cfg.setFinalityDelay) storageKeys.push("AnchorStateRegistryProxy");
        if (cfg.setWithdrawalDelay) storageKeys.push("DelayedWETH");

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            // Delays must not change during a pause as shortening one could make pending withdrawals
            // eligible the moment the chain unpauses.
            require(!_portal(chainId).paused(), string.concat("SetReviewPeriodDelays: ", chains[i].name, " is paused"));

            // SystemConfig.delayedWETH() is the canonical DelayedWETH pointer (StandardValidator DWETH-70).
            // The registry has no key for it, so register one to allow-list its storage writes.
            address weth = ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)).delayedWETH();
            if (weth != address(0)) {
                superchainAddrRegistry.saveAddress("DelayedWETH", chains[i], weth);
            }

            if (cfg.setProofMaturity) {
                IOptimismPortal2 portal = _portal(chainId);
                _requireVersion(portal.version(), MIN_PORTAL_VERSION, "OptimismPortal2", chains[i].name);
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
                _requireVersion(asr.version(), MIN_ASR_VERSION, "AnchorStateRegistry", chains[i].name);
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
                _requireVersion(IDelayedWETH(weth).version(), MIN_WETH_VERSION, "DelayedWETH", chains[i].name);
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

    /// @notice POLICY: portals that share an ETHLockbox from one interop set and must carry
    /// the same proof maturity delay, because the pooled liquidity exits after the shortest one.
    /// Only the chains in the task are visible, since set membership is not enumerable on-chain, so the
    /// task must list every chain of the set.
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

    /// @notice Reverts unless `version` is at least `minVersion`, so the task fails with a readable message
    /// when pointed at a contract that predates the setter.
    function _requireVersion(
        string memory version,
        string memory minVersion,
        string memory contractName,
        string memory chainName
    ) internal pure {
        require(
            SemverComp.gte(version, minVersion),
            string.concat(
                "SetReviewPeriodDelays: ", chainName, " ", contractName, " ", version, " is below ", minVersion
            )
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
