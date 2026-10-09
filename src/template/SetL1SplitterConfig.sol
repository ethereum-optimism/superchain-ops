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
    function transferOwnership(address newOwner) external;
    function acceptOwnership() external;
    function updateL1Recipient(address newRecipient) external;
    function updateMinWithdrawalAmount(uint256 newAmount) external;
}

/// @title SetL1SplitterConfig
/// @notice Configures the Unichain `L1Splitter` (L2, `Ownable2Step`, owned by an aliased L1 Safe) via
///         one portal deposit per call from that Safe:
///           - leg A (current owner): setters, then `transferOwnership(alias(newOwnerToAlias))`.
///           - leg B (new owner):     `acceptOwnership()`, then setters.
///         Config: `l1Splitter`, `l2RpcUrl` (required); `newOwnerToAlias` (leg A) or `acceptOwnership`
///         (leg B); optional `l1Recipient`, `minWithdrawalAmount` (skipped when unchanged).
///
/// @dev    Every call is dry-run as the aliased Safe on an `l2RpcUrl` fork, so an L2 revert fails the
///         simulation instead of silently on relay. `simulatePendingOwnerTransfer` (leg B only) sets
///         `pendingOwner` on that fork when leg A has not landed on L2 yet; it never touches the
///         signed payload, and the task must check `pendingOwner()` before execution.
contract SetL1SplitterConfig is L2TaskBase {
    using stdToml for string;

    /// @notice L2 gas limit per deposit.
    uint64 internal constant DEPOSIT_GAS_LIMIT = 150_000;

    /// @notice `Ownable2Step._pendingOwner` slot.
    bytes32 internal constant PENDING_OWNER_SLOT = bytes32(uint256(1));

    address public l1Splitter;
    address public newOwnerToAlias;
    bool public acceptOwnership;
    bool public simulatePendingOwnerTransfer;

    bool public setL1Recipient;
    address public l1Recipient;
    bool public setMinWithdrawalAmount;
    uint256 public minWithdrawalAmount;

    uint256 internal chainId;

    // Live L2 values, cached before the dry-run.
    address internal _liveL1Recipient;
    uint256 internal _liveMinWithdrawalAmount;

    /// @notice Overridable with `safeAddressString` in config.toml (leg A is signed by the current owner).
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
        // Accepts a decimal string (TOML integers are int64).
        if (setMinWithdrawalAmount) minWithdrawalAmount = toml.readUint(".minWithdrawalAmount");

        require(toml.keyExists(".l2RpcUrl"), "SetL1SplitterConfig: l2RpcUrl is required (L2 pre-flight)");
        _preflightL2(toml.readString(".l2RpcUrl"), _rootSafe);

        super._templateSetup(_taskConfigFilePath, _rootSafe);
    }

    /// @notice Assert the aliased root controls the splitter, cache live values, dry-run all calls.
    function _preflightL2(string memory _l2RpcUrl, address _rootSafe) internal {
        address aliasedRoot = AddressAliasHelper.applyL1ToL2Alias(_rootSafe);
        uint256 originalFork = vm.activeFork();
        vm.makePersistent(address(this)); // keep config and cache readable across the fork switch

        _createL2Fork(_l2RpcUrl);
        require(block.chainid == chainId, "SetL1SplitterConfig: l2RpcUrl chainId mismatch");
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

        vm.selectFork(originalFork);
    }

    /// @notice Virtual only so test harnesses can pin the L2 fork.
    function _createL2Fork(string memory _l2RpcUrl) internal virtual {
        vm.createSelectFork(_l2RpcUrl);
    }

    function _build(address) internal override {
        IOptimismPortal2 portal = IOptimismPortal2(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId));
        bytes[] memory calls = _calls();
        for (uint256 i; i < calls.length; i++) {
            portal.depositTransaction(l1Splitter, 0, DEPOSIT_GAS_LIMIT, false, calls[i]);
        }
    }

    /// @notice Deposits leave no payload in the L1 state diff, so check each action byte for byte.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
        bytes[] memory calls = _calls();
        require(_actions.length == calls.length, "SetL1SplitterConfig: action count mismatch");
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

    /// @notice L2 calls in order: acceptOwnership, changed setters, transferOwnership.
    function _calls() internal view returns (bytes[] memory calls) {
        calls = new bytes[](4);
        uint256 n;
        if (acceptOwnership) calls[n++] = abi.encodeCall(IL1Splitter.acceptOwnership, ());
        if (setL1Recipient && l1Recipient != _liveL1Recipient) {
            calls[n++] = abi.encodeCall(IL1Splitter.updateL1Recipient, (l1Recipient));
        }
        if (setMinWithdrawalAmount && minWithdrawalAmount != _liveMinWithdrawalAmount) {
            calls[n++] = abi.encodeCall(IL1Splitter.updateMinWithdrawalAmount, (minWithdrawalAmount));
        }
        if (newOwnerToAlias != address(0)) {
            calls[n++] =
                abi.encodeCall(IL1Splitter.transferOwnership, (AddressAliasHelper.applyL1ToL2Alias(newOwnerToAlias)));
        }
        assembly {
            mstore(calls, n) // trim to the calls actually emitted
        }
    }
}
