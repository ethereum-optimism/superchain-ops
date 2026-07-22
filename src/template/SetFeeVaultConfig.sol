// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {IFeeVault} from "src/interfaces/IFeeVault.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";

/// @notice Minimal L1 OptimismPortal2 interface (deposit only).
interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

/// @notice Reads the L2 ProxyAdmin owner during the pre-flight fork.
interface IProxyAdminView {
    function owner() external view returns (address);
}

/// @notice Reads a contract's semver during the pre-flight fork.
interface IVersioned {
    function version() external view returns (string memory);
}

/// @title SetFeeVaultConfig
/// @notice Updates the on-chain config (recipient / withdrawalNetwork / minWithdrawalAmount) of one
///         or more L2 fee-vault predeploys **in place**, via the fee vaults' own owner-gated setters
///         (`setRecipient` / `setWithdrawalNetwork` / `setMinWithdrawalAmount`) — NOT a proxy upgrade.
///         Calls are sent as `OptimismPortal2.depositTransaction()` from the L1 ProxyAdminOwner; the
///         deposit's aliased sender IS the L2 ProxyAdmin owner the setters authorize against.
///
///         Modular: `vaultProxies` may be any subset of the four fee-vault predeploys. For each
///         (chain, vault) only the fields that actually differ from live state produce a deposit
///         (per-field skip-unchanged). The skip set is re-derived from live L2 state on EVERY run
///         (`just execute` rebuilds the actions), so drift that flips a skip decision between
///         signing and execution changes the calldata and Safe tx hash, invalidating ALL collected
///         signatures — loud revert, full re-sign. At least one listed field must differ — a config
///         where every listed field already matches produces no actions and the framework reverts
///         with "No actions found".
///
///         Requires the vault to be on the mutable / `ProxyAdminOwnedBase` design that exposes the
///         setters — enforced by a per-vault minimum-version check (see `_minVersionFor`):
///           - SequencerFeeVault / BaseFeeVault / L1FeeVault : >= 1.6.0
///           - OperatorFeeVault                              : >= 1.1.0
///         Old immutable-recipient vaults (< min) must be migrated with `FeeVaultUpgradeTemplate`
///         first; this template rejects them at setup.
///
/// Supports: any OP Stack chain whose targeted FeeVaults meet the minimum versions above
///           (this template is keyed to FeeVault predeploy versions, not an op-contracts release).
///
/// @dev    Uses `L2TaskBase` (direct portal calls). Safe -> Multicall3.aggregate3Value ->
///         portal.depositTransaction x N. The required `l2RpcUrls` pre-flight forks each L2 to (1)
///         assert `ProxyAdmin.owner() == aliased root`, (2) enforce the version gate, (3) cache live
///         values for skip-unchanged, and (4) DRY-RUN the setter calls as the aliased owner so an
///         L2 revert surfaces here at setup instead of silently on relay.
contract SetFeeVaultConfig is L2TaskBase {
    using stdToml for string;

    // -------------------------------------------------------------------------
    // Fee-vault predeploys (same on every OP Stack chain)
    // -------------------------------------------------------------------------
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
    address internal constant OPERATOR_FEE_VAULT = 0x420000000000000000000000000000000000001b;

    /// @notice L2 gas limit for each setter deposit. Setters do one external `owner()` read plus a
    ///         single storage write and an event — 150k is comfortably sufficient.
    uint64 internal constant SETTER_GAS_LIMIT = 150_000;

    // -------------------------------------------------------------------------
    // Config inputs
    // -------------------------------------------------------------------------
    /// @notice Fee-vault predeploys to update (any subset of the four), from TOML `vaultProxies`.
    address[] public vaultProxies;

    /// @notice New recipients. Length is per-chain (== l2chains.length, applied to every vault on
    ///         the chain) or per-(chain, vault) flat chain-major (== l2chains.length * vaultProxies.length).
    address[] public recipients;
    /// @notice New withdrawal networks (0 = L1, 1 = L2). Same length rule as `recipients`.
    uint256[] public networks;
    /// @notice New minimum withdrawal amounts. Same length rule as `recipients`.
    uint256[] public minWithdrawalAmounts;

    // -------------------------------------------------------------------------
    // Cached live L2 state (captured on the pre-flight fork; keyed [chainId][vault])
    // -------------------------------------------------------------------------
    mapping(uint256 => mapping(address => address)) internal _liveRecipient;
    mapping(uint256 => mapping(address => uint256)) internal _liveNetwork;
    mapping(uint256 => mapping(address => uint256)) internal _liveMin;

    // -------------------------------------------------------------------------
    // L2TaskBase overrides
    // -------------------------------------------------------------------------
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    function _taskStorageWrites() internal pure override returns (string[] memory writes) {
        writes = new string[](1);
        writes[0] = "OptimismPortalProxy";
    }

    function _taskBalanceChanges() internal pure override returns (string[] memory) {}

    function _getCodeExceptions() internal pure override returns (address[] memory) {
        return new address[](0);
    }

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        string memory toml = vm.readFile(_taskConfigFilePath);

        vaultProxies = abi.decode(toml.parseRaw(".vaultProxies"), (address[]));
        require(vaultProxies.length > 0, "SetFeeVaultConfig: vaultProxies must not be empty");
        for (uint256 i; i < vaultProxies.length; i++) {
            _requireKnownVault(vaultProxies[i]);
            // Duplicates would re-cache live values AFTER the first occurrence's dry-run mutated
            // the pre-flight fork, making _build silently emit zero deposits for that vault.
            for (uint256 j; j < i; j++) {
                require(
                    vaultProxies[j] != vaultProxies[i],
                    string.concat("SetFeeVaultConfig: duplicate vaultProxies entry ", vm.toString(vaultProxies[i]))
                );
            }
        }

        recipients = abi.decode(toml.parseRaw(".recipients"), (address[]));
        networks = abi.decode(toml.parseRaw(".networks"), (uint256[]));
        minWithdrawalAmounts = abi.decode(toml.parseRaw(".minWithdrawalAmounts"), (uint256[]));

        uint256 nChains = chains.length;
        uint256 nVaults = vaultProxies.length;
        _requireLen(recipients.length, nChains, nVaults, "recipients");
        _requireLen(networks.length, nChains, nVaults, "networks");
        _requireLen(minWithdrawalAmounts.length, nChains, nVaults, "minWithdrawalAmounts");

        for (uint256 i; i < recipients.length; i++) {
            require(recipients[i] != address(0), "SetFeeVaultConfig: recipient cannot be the zero address");
        }
        for (uint256 i; i < networks.length; i++) {
            require(networks[i] <= 1, "SetFeeVaultConfig: network must be 0 (L1) or 1 (L2)");
        }

        _preflightL2(toml, chains, _rootSafe);

        super._templateSetup(_taskConfigFilePath, _rootSafe);
    }

    /// @notice REQUIRED L2 pre-flight. For each chain forks the L2 to: assert the L2 ProxyAdmin owner
    ///         is the aliased root, enforce the per-vault version gate, cache live values, and dry-run
    ///         the setter calls (as the aliased owner) so any L2 revert fails setup here — not silently
    ///         on relay (the failure mode that bit the earlier fee-vault task).
    function _preflightL2(string memory toml, SuperchainAddressRegistry.ChainInfo[] memory chains, address _rootSafe)
        internal
    {
        require(toml.keyExists(".l2RpcUrls"), "SetFeeVaultConfig: l2RpcUrls is required (L2 pre-flight)");
        string[] memory l2RpcUrls = abi.decode(toml.parseRaw(".l2RpcUrls"), (string[]));
        require(l2RpcUrls.length == chains.length, "SetFeeVaultConfig: l2RpcUrls length must equal l2chains.length");

        address aliasedRoot = AddressAliasHelper.applyL1ToL2Alias(_rootSafe);
        vm.label(aliasedRoot, "AliasedL1PAO (L2 ProxyAdmin owner)");
        for (uint256 v; v < vaultProxies.length; v++) {
            vm.label(vaultProxies[v], _vaultLabel(vaultProxies[v]));
        }
        uint256 originalFork = vm.activeFork();
        uint256 nChains = chains.length;

        // Persist this template across the L2 forks below, so its config arrays remain readable on the
        // fork and the live-value cache written here survives the switch back to the original fork.
        vm.makePersistent(address(this));

        for (uint256 c; c < nChains; c++) {
            _createL2Fork(l2RpcUrls[c], c);
            uint256 cid = chains[c].chainId;
            require(
                block.chainid == cid,
                string.concat(
                    "SetFeeVaultConfig: l2RpcUrls[",
                    vm.toString(c),
                    "] chainId=",
                    vm.toString(block.chainid),
                    " != l2chains[",
                    vm.toString(c),
                    "].chainId=",
                    vm.toString(cid)
                )
            );

            address l2Owner = IProxyAdminView(Predeploys.PROXY_ADMIN).owner();
            require(
                l2Owner == aliasedRoot,
                string.concat(
                    "SetFeeVaultConfig: L2 ProxyAdmin on chainId ",
                    vm.toString(cid),
                    " owner is ",
                    vm.toString(l2Owner),
                    " -- expected aliased root ",
                    vm.toString(aliasedRoot),
                    ". Setter deposits would revert on L2. Fix L2 ProxyAdmin ownership first."
                )
            );

            for (uint256 v; v < vaultProxies.length; v++) {
                address vault = vaultProxies[v];

                // (1) capability gate — reject old immutable vaults that have no setters.
                _requireSetterCapable(vault);

                // (2) cache live values BEFORE any dry-run mutation.
                _liveRecipient[cid][vault] = IFeeVault(vault).recipient();
                _liveNetwork[cid][vault] = uint256(IFeeVault(vault).withdrawalNetwork());
                _liveMin[cid][vault] = IFeeVault(vault).minWithdrawalAmount();

                // (3) dry-run the setters that will actually change, as the aliased owner.
                address newR = _recipientFor(c, v, nChains);
                uint256 newN = _networkFor(c, v, nChains);
                uint256 newM = _minFor(c, v, nChains);
                vm.startPrank(aliasedRoot);
                if (newR != _liveRecipient[cid][vault]) IFeeVault(vault).setRecipient(newR);
                if (newN != _liveNetwork[cid][vault]) {
                    IFeeVault(vault).setWithdrawalNetwork(IFeeVault.WithdrawalNetwork(newN));
                }
                if (newM != _liveMin[cid][vault]) IFeeVault(vault).setMinWithdrawalAmount(newM);
                vm.stopPrank();
            }
        }

        vm.selectFork(originalFork);
    }

    /// @notice Creates and selects the L2 pre-flight fork for one chain. Production tasks ALWAYS
    ///         fork latest — the ProxyAdmin-owner assertion, version gate, and skip-unchanged
    ///         decisions must see live sign-time state, and fork selection is deliberately NOT
    ///         configurable from the task config. Virtual ONLY so test harnesses (see the pinned
    ///         subclass in test/tasks/Regression.t.sol) can pin the fork for deterministic
    ///         fixtures; the second parameter is the `l2chains` index for multi-chain harnesses.
    function _createL2Fork(string memory _l2RpcUrl, uint256) internal virtual {
        vm.createSelectFork(_l2RpcUrl);
    }

    /// @notice Builds one portal deposit per field that differs from live state (per-field skip-unchanged).
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        uint256 nChains = chains.length;

        for (uint256 c; c < nChains; c++) {
            uint256 cid = chains[c].chainId;
            address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", cid);

            for (uint256 v; v < vaultProxies.length; v++) {
                address vault = vaultProxies[v];
                address newR = _recipientFor(c, v, nChains);
                uint256 newN = _networkFor(c, v, nChains);
                uint256 newM = _minFor(c, v, nChains);

                if (newR != _liveRecipient[cid][vault]) {
                    IOptimismPortal2(portal).depositTransaction(
                        vault, 0, SETTER_GAS_LIMIT, false, abi.encodeCall(IFeeVault.setRecipient, (newR))
                    );
                }
                if (newN != _liveNetwork[cid][vault]) {
                    IOptimismPortal2(portal).depositTransaction(
                        vault,
                        0,
                        SETTER_GAS_LIMIT,
                        false,
                        abi.encodeCall(IFeeVault.setWithdrawalNetwork, (IFeeVault.WithdrawalNetwork(newN)))
                    );
                }
                if (newM != _liveMin[cid][vault]) {
                    IOptimismPortal2(portal).depositTransaction(
                        vault, 0, SETTER_GAS_LIMIT, false, abi.encodeCall(IFeeVault.setMinWithdrawalAmount, (newM))
                    );
                }
            }
        }
    }

    /// @notice Re-derives the exact expected deposit set (same order and skip rules as `_build`) and
    ///         asserts each captured action byte-for-byte: positional per-chain portal target, zero
    ///         value, and the full `depositTransaction` calldata (vault, value, gas limit, isCreation,
    ///         inner setter call). This anchors precisely what signers sign — no other L1-side
    ///         artifact can, since value-0 deposits leave no payload-bearing L1 state diff.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        uint256 nChains = chains.length;

        uint256 cursor;
        // NOTE: MUST mirror _build's iteration order and skip-unchanged conditions exactly.
        for (uint256 c; c < nChains; c++) {
            uint256 cid = chains[c].chainId;
            address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", cid);
            for (uint256 v; v < vaultProxies.length; v++) {
                address vault = vaultProxies[v];
                address newR = _recipientFor(c, v, nChains);
                uint256 newN = _networkFor(c, v, nChains);
                uint256 newM = _minFor(c, v, nChains);

                if (newR != _liveRecipient[cid][vault]) {
                    cursor =
                        _checkDeposit(_actions, cursor, portal, vault, abi.encodeCall(IFeeVault.setRecipient, (newR)));
                }
                if (newN != _liveNetwork[cid][vault]) {
                    cursor = _checkDeposit(
                        _actions,
                        cursor,
                        portal,
                        vault,
                        abi.encodeCall(IFeeVault.setWithdrawalNetwork, (IFeeVault.WithdrawalNetwork(newN)))
                    );
                }
                if (newM != _liveMin[cid][vault]) {
                    cursor = _checkDeposit(
                        _actions, cursor, portal, vault, abi.encodeCall(IFeeVault.setMinWithdrawalAmount, (newM))
                    );
                }
            }
        }

        require(
            _actions.length == cursor,
            string.concat(
                "SetFeeVaultConfig: expected ", vm.toString(cursor), " deposits, got ", vm.toString(_actions.length)
            )
        );

        MultisigTaskPrinter.printTitle("SetFeeVaultConfig: validated portal deposit actions");
    }

    /// @notice Asserts action `i` is exactly `depositTransaction(vault, 0, SETTER_GAS_LIMIT, false, inner)`
    ///         sent to `portal` with zero value; returns the advanced cursor.
    function _checkDeposit(Action[] memory _actions, uint256 i, address portal, address vault, bytes memory inner)
        internal
        pure
        returns (uint256)
    {
        require(i < _actions.length, "SetFeeVaultConfig: missing expected deposit");
        require(_actions[i].target == portal, "SetFeeVaultConfig: action target mismatch");
        require(_actions[i].value == 0, "SetFeeVaultConfig: action value must be 0");
        require(
            keccak256(_actions[i].arguments)
                == keccak256(
                    abi.encodeCall(IOptimismPortal2.depositTransaction, (vault, 0, SETTER_GAS_LIMIT, false, inner))
                ),
            "SetFeeVaultConfig: action calldata mismatch"
        );
        return i + 1;
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /// @notice Per-(chain, vault) selector honoring the per-chain vs per-vault-flat array shape.
    function _idx(uint256 len, uint256 c, uint256 v, uint256 nChains) internal view returns (uint256) {
        return len == nChains ? c : c * vaultProxies.length + v;
    }

    function _recipientFor(uint256 c, uint256 v, uint256 nChains) internal view returns (address) {
        return recipients[_idx(recipients.length, c, v, nChains)];
    }

    function _networkFor(uint256 c, uint256 v, uint256 nChains) internal view returns (uint256) {
        return networks[_idx(networks.length, c, v, nChains)];
    }

    function _minFor(uint256 c, uint256 v, uint256 nChains) internal view returns (uint256) {
        return minWithdrawalAmounts[_idx(minWithdrawalAmounts.length, c, v, nChains)];
    }

    function _requireLen(uint256 len, uint256 nChains, uint256 nVaults, string memory field) internal pure {
        require(
            len == nChains || len == nChains * nVaults,
            string.concat(
                "SetFeeVaultConfig: ",
                field,
                " length must equal l2chains.length or l2chains.length*vaultProxies.length"
            )
        );
    }

    /// @notice Human-readable label for a known fee-vault predeploy (debugging aid via vm.label).
    function _vaultLabel(address _vault) internal pure returns (string memory) {
        if (_vault == SEQUENCER_FEE_VAULT) return "SequencerFeeVault";
        if (_vault == BASE_FEE_VAULT) return "BaseFeeVault";
        if (_vault == L1_FEE_VAULT) return "L1FeeVault";
        if (_vault == OPERATOR_FEE_VAULT) return "OperatorFeeVault";
        return "UnknownFeeVault";
    }

    function _requireKnownVault(address _vault) internal pure {
        require(
            _vault == SEQUENCER_FEE_VAULT || _vault == BASE_FEE_VAULT || _vault == L1_FEE_VAULT
                || _vault == OPERATOR_FEE_VAULT,
            "SetFeeVaultConfig: unknown vault address"
        );
    }

    /// @notice Minimum FeeVault version that exposes the owner-gated setters, per vault type.
    ///         Setters shipped at OperatorFeeVault 1.1.0 / FeeVault 1.6.0 together (upstream
    ///         ethereum-optimism/optimism#17536, commit 0f21af94 — the commit `FeeVaultUpgrader`'s
    ///         baked impls are built from); the 1.1.1/1.6.1 bump (#19564) changed no setter
    ///         behavior, so gating Operator above 1.1.0 would reject the exact implementation
    ///         `FeeVaultUpgradeTemplate` deploys.
    function _minVersionFor(address _vault) internal pure returns (uint256 major, uint256 minor, uint256 patch) {
        if (_vault == OPERATOR_FEE_VAULT) return (1, 1, 0);
        return (1, 6, 0); // Sequencer / Base / L1
    }

    /// @notice Reverts unless the live vault version is >= its per-type minimum (has `setRecipient`).
    ///         Low-level staticcall: an "absent" predeploy is a genesis Proxy with an UNSET impl
    ///         (call reverts) or, on non-standard chains, truly codeless (call succeeds with empty
    ///         returndata — uncatchable by try/catch: decode failures escape the catch clause);
    ///         both shapes get one actionable message instead of a context-free revert.
    function _requireSetterCapable(address _vault) internal view {
        (bool ok, bytes memory ret) = _vault.staticcall(abi.encodeCall(IVersioned.version, ()));
        require(
            ok && ret.length >= 64, // 64 = minimum well-formed ABI encoding of a `string` return
            string.concat(
                "SetFeeVaultConfig: ",
                _vaultLabel(_vault),
                " is not live on this chain (predeploy implementation unset or no code) -- remove it from vaultProxies"
            )
        );
        (uint256 rMaj, uint256 rMin, uint256 rPat) = _minVersionFor(_vault);
        require(
            _versionGte(abi.decode(ret, (string)), rMaj, rMin, rPat),
            "SetFeeVaultConfig: FeeVault version too old - no setters (migrate with FeeVaultUpgradeTemplate first)"
        );
    }

    /// @notice True if `_version` (semver) >= `rMaj.rMin.rPat`. A pre-release of the exact min core
    ///         version (e.g. "1.6.0-rc.1" vs 1.6.0) is treated as strictly less than the release.
    function _versionGte(string memory _version, uint256 rMaj, uint256 rMin, uint256 rPat)
        internal
        pure
        returns (bool)
    {
        (uint256 maj, uint256 minor, uint256 patch, bool prerelease) = _parseSemver(_version);
        if (maj != rMaj) return maj > rMaj;
        if (minor != rMin) return minor > rMin;
        if (patch != rPat) return patch > rPat;
        return !prerelease;
    }

    /// @notice Parses a leading `major.minor.patch` from a semver string; `prerelease` is true if any
    ///         non-empty suffix (e.g. "-beta.6", "+build") follows the patch number.
    function _parseSemver(string memory _s)
        internal
        pure
        returns (uint256 major, uint256 minor, uint256 patch, bool prerelease)
    {
        bytes memory b = bytes(_s);
        uint256 i;
        (major, i) = _readNum(b, i, true);
        (minor, i) = _readNum(b, i, true);
        (patch, i) = _readNum(b, i, false);
        prerelease = i < b.length; // anything left after patch (e.g. '-'/'+') marks a pre-release/build.
    }

    /// @notice Reads a run of ASCII digits starting at `i`; if `expectDot`, skips a trailing '.'.
    function _readNum(bytes memory b, uint256 i, bool expectDot) internal pure returns (uint256 val, uint256 next) {
        while (i < b.length && b[i] >= 0x30 && b[i] <= 0x39) {
            val = val * 10 + (uint8(b[i]) - 48);
            i++;
        }
        if (expectDot && i < b.length && b[i] == 0x2e) i++;
        next = i;
    }
}
