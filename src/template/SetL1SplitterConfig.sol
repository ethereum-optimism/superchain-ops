// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

/// @notice Minimal L1 OptimismPortal2 interface (deposit only).
interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

/// @notice Uniswap unichain-contracts `src/FeeSplitter/L1Splitter.sol` (OZ `Ownable2Step`).
interface IL1Splitter {
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function l1Recipient() external view returns (address);
    function minWithdrawalAmount() external view returns (uint256);
    function feeDisbursementInterval() external view returns (uint48);
    function transferOwnership(address newOwner) external;
    function acceptOwnership() external;
    function updateL1Recipient(address newRecipient) external;
    function updateMinWithdrawalAmount(uint256 newAmount) external;
    function updateFeeDisbursementInterval(uint48 newInterval) external;
}

/// @title SetL1SplitterConfig
/// @notice Configures an L2 `L1Splitter` (Uniswap unichain-contracts, `Ownable2Step`) owned by the
///         alias of an L1 Safe, via `OptimismPortal2.depositTransaction()` from that Safe. Covers both
///         legs of an ownership handover plus the owner-gated setters:
///           - leg A (current owner): optional setters, then `transferOwnership(alias(newOwnerToAlias))`.
///           - leg B (new owner):     `acceptOwnership()`, then optional setters.
///         Deposits are emitted in that order, one per call; setters whose value already matches live
///         L2 state are skipped. At least one call must result, otherwise the framework reverts with
///         "No actions found".
///
///         Config (all optional except `l1Splitter` and `l2RpcUrl`; `newOwnerToAlias` and
///         `acceptOwnership` are mutually exclusive, they are signed by different Safes):
///           l1Splitter, l2RpcUrl, newOwnerToAlias, acceptOwnership, l1Recipient,
///           minWithdrawalAmount, feeDisbursementInterval, simulatePendingOwnerTransfer.
///
///         The root Safe is `ProxyAdminOwner` unless `safeAddressString` overrides it.
///
/// @dev    The required `l2RpcUrl` pre-flight forks the L2 to (1) assert the aliased root Safe is the
///         splitter's `owner()` (leg A) or `pendingOwner()` (leg B), (2) cache live values for
///         skip-unchanged, and (3) DRY-RUN every call as the aliased root and assert the resulting
///         state, so an L2 revert surfaces at setup instead of silently on relay.
///
///         `simulatePendingOwnerTransfer = true` (leg B only) writes the `Ownable2Step` pending-owner
///         slot on the pre-flight fork, standing in for a leg-A deposit that has executed on L1 but is
///         not yet relayed on L2 (or not yet executed in a stacked simulation). Remove it once
///         `pendingOwner()` is live, and check `pendingOwner()` before execution: if leg A never
///         landed, the leg-B deposits would revert on L2.
contract SetL1SplitterConfig is L2TaskBase {
    using stdToml for string;

    /// @notice L2 gas limit for each deposit. Each call is one or two storage writes and an event.
    uint64 internal constant DEPOSIT_GAS_LIMIT = 150_000;

    /// @notice OZ v5 `Ownable2Step._pendingOwner` storage slot (`Ownable._owner` is slot 0).
    bytes32 internal constant PENDING_OWNER_SLOT = bytes32(uint256(1));

    /// @notice Blocks behind the reported L2 head at which the pre-flight fork is created.
    uint256 internal constant L2_FORK_HEAD_LAG = 5;

    // -------------------------------------------------------------------------
    // Config inputs
    // -------------------------------------------------------------------------
    address public l1Splitter;
    address public newOwnerToAlias;
    bool public acceptOwnership;
    bool public simulatePendingOwnerTransfer;

    bool public setL1Recipient;
    address public l1Recipient;
    bool public setMinWithdrawalAmount;
    uint256 public minWithdrawalAmount;
    bool public setFeeDisbursementInterval;
    uint48 public feeDisbursementInterval;

    /// @notice The single chain targeted by this task.
    uint256 internal chainId;

    // -------------------------------------------------------------------------
    // Cached live L2 state (captured on the pre-flight fork, before the dry-run)
    // -------------------------------------------------------------------------
    address internal _liveL1Recipient;
    uint256 internal _liveMinWithdrawalAmount;
    uint48 internal _liveFeeDisbursementInterval;

    // -------------------------------------------------------------------------
    // L2TaskBase overrides
    // -------------------------------------------------------------------------
    /// @notice Default Safe name. Can be overridden via `safeAddressString` in config.toml.
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
        require(chains.length == 1, "SetL1SplitterConfig: exactly one chain required");
        chainId = chains[0].chainId;

        string memory toml = vm.readFile(_taskConfigFilePath);
        l1Splitter = toml.readAddress(".l1Splitter");
        require(l1Splitter != address(0), "SetL1SplitterConfig: l1Splitter is zero address");

        if (toml.keyExists(".newOwnerToAlias")) {
            newOwnerToAlias = toml.readAddress(".newOwnerToAlias");
            require(newOwnerToAlias != address(0), "SetL1SplitterConfig: newOwnerToAlias is zero address");
            require(newOwnerToAlias != _rootSafe, "SetL1SplitterConfig: newOwnerToAlias equals root safe");
        }
        acceptOwnership = toml.keyExists(".acceptOwnership") && toml.readBool(".acceptOwnership");
        require(
            !(acceptOwnership && newOwnerToAlias != address(0)),
            "SetL1SplitterConfig: newOwnerToAlias and acceptOwnership are mutually exclusive"
        );
        simulatePendingOwnerTransfer =
            toml.keyExists(".simulatePendingOwnerTransfer") && toml.readBool(".simulatePendingOwnerTransfer");
        require(
            !simulatePendingOwnerTransfer || acceptOwnership,
            "SetL1SplitterConfig: simulatePendingOwnerTransfer requires acceptOwnership"
        );

        setL1Recipient = toml.keyExists(".l1Recipient");
        if (setL1Recipient) l1Recipient = toml.readAddress(".l1Recipient");
        setMinWithdrawalAmount = toml.keyExists(".minWithdrawalAmount");
        // Typed reader: accepts a bare integer or a decimal string (TOML integers are int64-bounded).
        if (setMinWithdrawalAmount) minWithdrawalAmount = toml.readUint(".minWithdrawalAmount");
        setFeeDisbursementInterval = toml.keyExists(".feeDisbursementInterval");
        if (setFeeDisbursementInterval) {
            uint256 interval = toml.readUint(".feeDisbursementInterval");
            require(interval <= type(uint48).max, "SetL1SplitterConfig: feeDisbursementInterval exceeds uint48");
            feeDisbursementInterval = uint48(interval);
        }

        require(toml.keyExists(".l2RpcUrl"), "SetL1SplitterConfig: l2RpcUrl is required (L2 pre-flight)");
        _preflightL2(toml.readString(".l2RpcUrl"), _rootSafe);

        super._templateSetup(_taskConfigFilePath, _rootSafe);
    }

    /// @notice REQUIRED L2 pre-flight: assert the aliased root controls the splitter, cache live
    ///         values, then dry-run every call in deposit order and assert the resulting state.
    function _preflightL2(string memory _l2RpcUrl, address _rootSafe) internal {
        address aliasedRoot = AddressAliasHelper.applyL1ToL2Alias(_rootSafe);
        vm.label(aliasedRoot, "AliasedRootSafe");
        vm.label(l1Splitter, "L1Splitter");
        uint256 originalFork = vm.activeFork();
        // Keep this template's config and cache readable across the fork switch.
        vm.makePersistent(address(this));

        _createL2Fork(_l2RpcUrl);
        require(
            block.chainid == chainId,
            string.concat(
                "SetL1SplitterConfig: l2RpcUrl chainId=",
                vm.toString(block.chainid),
                " != l2chains[0].chainId=",
                vm.toString(chainId)
            )
        );
        require(l1Splitter.code.length > 0, "SetL1SplitterConfig: l1Splitter has no code on L2");
        IL1Splitter splitter = IL1Splitter(l1Splitter);

        if (simulatePendingOwnerTransfer) {
            address livePending = splitter.pendingOwner();
            require(
                livePending == address(0) || livePending == aliasedRoot,
                "SetL1SplitterConfig: simulatePendingOwnerTransfer would overwrite a different pendingOwner"
            );
            vm.store(l1Splitter, PENDING_OWNER_SLOT, bytes32(uint256(uint160(aliasedRoot))));
            MultisigTaskPrinter.printTitle("SetL1SplitterConfig: simulating pendingOwner = aliased root on L2");
        }

        if (acceptOwnership) {
            require(splitter.pendingOwner() == aliasedRoot, "SetL1SplitterConfig: pendingOwner is not the aliased root");
        } else {
            require(splitter.owner() == aliasedRoot, "SetL1SplitterConfig: owner is not the aliased root");
        }

        _liveL1Recipient = splitter.l1Recipient();
        _liveMinWithdrawalAmount = splitter.minWithdrawalAmount();
        _liveFeeDisbursementInterval = splitter.feeDisbursementInterval();

        bytes[] memory calls = _calls();
        require(calls.length > 0, "SetL1SplitterConfig: every configured value already matches live state");
        vm.startPrank(aliasedRoot);
        for (uint256 i; i < calls.length; i++) {
            (bool ok,) = l1Splitter.call(calls[i]);
            require(ok, string.concat("SetL1SplitterConfig: L2 dry-run reverted at call ", vm.toString(i)));
        }
        vm.stopPrank();

        require(splitter.owner() == aliasedRoot, "SetL1SplitterConfig: dry-run owner mismatch");
        address expectedPending =
            newOwnerToAlias != address(0) ? AddressAliasHelper.applyL1ToL2Alias(newOwnerToAlias) : address(0);
        require(splitter.pendingOwner() == expectedPending, "SetL1SplitterConfig: dry-run pendingOwner mismatch");
        if (setL1Recipient) require(splitter.l1Recipient() == l1Recipient, "SetL1SplitterConfig: dry-run l1Recipient");
        if (setMinWithdrawalAmount) {
            require(splitter.minWithdrawalAmount() == minWithdrawalAmount, "SetL1SplitterConfig: dry-run minimum");
        }
        if (setFeeDisbursementInterval) {
            require(
                splitter.feeDisbursementInterval() == feeDisbursementInterval, "SetL1SplitterConfig: dry-run interval"
            );
        }

        vm.selectFork(originalFork);
    }

    /// @notice Creates and selects the L2 pre-flight fork. Production tasks fork `L2_FORK_HEAD_LAG`
    ///         blocks behind the reported head, because load-balanced public L2 RPCs can report a
    ///         head the serving node does not have yet; virtual only so test harnesses can pin the
    ///         fork for deterministic fixtures.
    function _createL2Fork(string memory _l2RpcUrl) internal virtual {
        vm.createSelectFork(_l2RpcUrl, _l2Head(_l2RpcUrl) - L2_FORK_HEAD_LAG);
    }

    /// @notice Head block number reported by `_l2RpcUrl`, via `eth_blockNumber`.
    function _l2Head(string memory _l2RpcUrl) internal returns (uint256 head) {
        bytes memory raw = vm.rpc(_l2RpcUrl, "eth_blockNumber", "[]");
        for (uint256 i; i < raw.length; i++) {
            head = (head << 8) | uint8(raw[i]);
        }
    }

    /// @notice One portal deposit per resolved call, in `_calls()` order.
    function _build(address) internal override {
        IOptimismPortal2 portal = IOptimismPortal2(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId));
        bytes[] memory calls = _calls();
        for (uint256 i; i < calls.length; i++) {
            portal.depositTransaction(l1Splitter, 0, DEPOSIT_GAS_LIMIT, false, calls[i]);
        }
    }

    /// @notice Asserts each captured action is exactly the expected deposit, byte for byte. Value-0
    ///         deposits leave no payload-bearing L1 state diff, so this is what anchors the payload.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
        bytes[] memory calls = _calls();
        require(
            _actions.length == calls.length,
            string.concat(
                "SetL1SplitterConfig: expected ",
                vm.toString(calls.length),
                " deposits, got ",
                vm.toString(_actions.length)
            )
        );
        for (uint256 i; i < calls.length; i++) {
            require(_actions[i].target == portal, "SetL1SplitterConfig: action target mismatch");
            require(_actions[i].value == 0, "SetL1SplitterConfig: action value must be 0");
            require(
                keccak256(_actions[i].arguments)
                    == keccak256(
                        abi.encodeCall(
                            IOptimismPortal2.depositTransaction, (l1Splitter, 0, DEPOSIT_GAS_LIMIT, false, calls[i])
                        )
                    ),
                "SetL1SplitterConfig: action calldata mismatch"
            );
        }
        MultisigTaskPrinter.printTitle("SetL1SplitterConfig: validated portal deposit actions");
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /// @notice The L2 calls, in order: acceptOwnership, changed setters, transferOwnership.
    ///         Depends only on config and the cached pre-dry-run live values.
    function _calls() internal view returns (bytes[] memory calls) {
        calls = new bytes[](5);
        uint256 n;
        if (acceptOwnership) calls[n++] = abi.encodeCall(IL1Splitter.acceptOwnership, ());
        if (setL1Recipient && l1Recipient != _liveL1Recipient) {
            calls[n++] = abi.encodeCall(IL1Splitter.updateL1Recipient, (l1Recipient));
        }
        if (setMinWithdrawalAmount && minWithdrawalAmount != _liveMinWithdrawalAmount) {
            calls[n++] = abi.encodeCall(IL1Splitter.updateMinWithdrawalAmount, (minWithdrawalAmount));
        }
        if (setFeeDisbursementInterval && feeDisbursementInterval != _liveFeeDisbursementInterval) {
            calls[n++] = abi.encodeCall(IL1Splitter.updateFeeDisbursementInterval, (feeDisbursementInterval));
        }
        if (newOwnerToAlias != address(0)) {
            calls[n++] =
                abi.encodeCall(IL1Splitter.transferOwnership, (AddressAliasHelper.applyL1ToL2Alias(newOwnerToAlias)));
        }
        assembly {
            mstore(calls, n)
        }
    }
}
