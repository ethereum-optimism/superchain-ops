// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {FeeVaultUpgradeTemplate} from "src/template/FeeVaultUpgradeTemplate.sol";

/// @title FeeVaultUpgradeTemplateIntegrationTest
/// @notice End-to-end proof that `FeeVaultUpgradeTemplate` actually updates the L2 fee-vault
///         recipients — the thing the pre-fix template silently failed to do.
///
///         It simulates the L1 Safe task on a Sepolia fork, captures the L1->L2 portal deposits,
///         replays them on an OP Sepolia fork, and asserts the on-chain result.
///
///         OP Sepolia is the ideal target: its vaults ship the OLD immutable-recipient generation
///         (`version() == "1.3.1"`, where `recipient()` / `withdrawalNetwork()` REVERT and only the
///         immutable `RECIPIENT()` getter exists), and its L2 ProxyAdmin is owned by the aliased L1
///         ProxyAdminOwner — exactly the address the portal deposits execute as. After the task the
///         vaults are on `v1.6.0`, where the recipient lives in storage and was set via `setRecipient`.
///
///         This is a fork test, so (like every `*Integration` test in this repo) it is skipped in CI
///         (`forge test --skip Integration`) and run manually:
///
///         forge test --match-contract FeeVaultUpgradeTemplateIntegration -vvv
contract FeeVaultUpgradeTemplateIntegrationTest is Test {
    FeeVaultUpgradeTemplate public template;

    uint256 internal sepoliaForkId;
    uint256 internal opSepoliaForkId;

    // OP Sepolia OptimismPortal on L1 (from the example config `[addresses]`).
    address internal constant OP_SEPOLIA_PORTAL = 0x16Fc5058F25648194471939df75CF27A2fdC48BC;

    // L2 fee-vault predeploys upgraded by the example config (Sequencer, Base, L1).
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;

    // New recipient configured by the example config.
    address internal constant NEW_RECIPIENT = 0xE75f598754A552841E65f43197C85028874A96a4;

    string internal constant CONFIG_PATH = "test/tasks/example/sep/034-arena-z-fee-vault-upgrade/config.toml";

    function setUp() public {
        string memory sepoliaRpc = vm.envOr("SEPOLIA_RPC_URL", string("https://ci-sepolia-l1-archive.optimism.io"));
        sepoliaForkId = vm.createFork(sepoliaRpc);

        string memory opSepoliaRpc = vm.envOr("OP_SEPOLIA_RPC_URL", string("https://sepolia.optimism.io"));
        opSepoliaForkId = vm.createFork(opSepoliaRpc);

        vm.selectFork(sepoliaForkId);
        template = new FeeVaultUpgradeTemplate();
    }

    /// @notice Full proof: vaults start on the old immutable impl, the task runs, the recipients change.
    function test_feeVaultUpgrade_updatesRecipients_integration() public {
        // --- Step 1: pre-state on L2 — the OLD immutable generation ---
        vm.selectFork(opSepoliaForkId);
        // The legacy immutable getter still reads the pre-task recipient...
        assertTrue(_legacyRecipient(SEQUENCER_FEE_VAULT) != NEW_RECIPIENT, "Seq already on new recipient (pre)");
        // ...but the v1.6.0 storage getter does not exist yet, so it reverts.
        assertFalse(_storageRecipientReadable(SEQUENCER_FEE_VAULT), "recipient() unexpectedly readable pre-upgrade");
        console2.log("pre  SequencerFeeVault version:", _version(SEQUENCER_FEE_VAULT));

        // --- Step 2: simulate the L1 task and capture the portal deposits ---
        vm.selectFork(sepoliaForkId);
        vm.recordLogs();
        template.simulate(CONFIG_PATH);
        Vm.Log[] memory allLogs = vm.getRecordedLogs();

        // --- Step 3: replay the deposits on L2 ---
        uint256 relayed = _relayDepositsToL2(allLogs);
        // 2 CREATE2 deploys + 3 vaults x (1 upgrade + 3 setters) = 14 deposits.
        assertEq(relayed, 14, "expected 14 successful L1->L2 deposits");

        // --- Step 4: post-state on L2 — recipients updated, now on the storage-backed v1.6.0 impl ---
        vm.selectFork(opSepoliaForkId);
        _assertUpgraded(SEQUENCER_FEE_VAULT);
        _assertUpgraded(BASE_FEE_VAULT);
        _assertUpgraded(L1_FEE_VAULT);
    }

    /// @notice Replays every TransactionDeposited event emitted by the OP Sepolia portal onto the L2 fork.
    /// @return successCount number of deposits that executed successfully on L2.
    function _relayDepositsToL2(Vm.Log[] memory allLogs) internal returns (uint256 successCount) {
        vm.selectFork(opSepoliaForkId);

        bytes32 txDepositedSelector = keccak256("TransactionDeposited(address,address,uint256,bytes)");
        // Simulations emit events twice (dry-run + actual); take the second half.
        uint256 startIndex = allLogs.length / 2;
        uint256 txCount;

        for (uint256 i = startIndex; i < allLogs.length; i++) {
            if (allLogs[i].topics[0] != txDepositedSelector) continue;
            if (allLogs[i].emitter != OP_SEPOLIA_PORTAL) continue;

            address from = address(uint160(uint256(allLogs[i].topics[1])));
            address to = address(uint160(uint256(allLogs[i].topics[2])));
            bytes memory opaqueData = abi.decode(allLogs[i].data, (bytes));

            // opaqueData layout: value(32) + mint(32) + gasLimit(8) + isCreation(1) + data(...)
            uint256 value = uint256(bytes32(_slice(opaqueData, 0, 32)));
            uint64 gasLimit = uint64(bytes8(_slice(opaqueData, 64, 8)));
            bytes memory data = _slice(opaqueData, 73, opaqueData.length - 73);

            txCount++;
            vm.prank(from);
            (bool ok,) = to.call{value: value, gas: gasLimit}(data);
            if (ok) successCount++;
            else console2.log("deposit FAILED, index", txCount);
        }

        console2.log("deposits relayed:", txCount, "succeeded:", successCount);
        assertEq(txCount, 14, "expected exactly 14 deposits in the batch");
    }

    /// @notice Asserts a vault was upgraded to v1.6.0 and fully reconfigured via the storage setters.
    function _assertUpgraded(address vault) internal view {
        assertEq(_version(vault), "1.6.0", "version not bumped to 1.6.0");
        // The storage getter now exists AND returns the new recipient (proves setRecipient took effect).
        assertTrue(_storageRecipientReadable(vault), "recipient() still unreadable post-upgrade");
        assertEq(_storageRecipient(vault), NEW_RECIPIENT, "recipient() mismatch");
        // The legacy getter reads the same storage slot in v1.6.0, so it agrees.
        assertEq(_legacyRecipient(vault), NEW_RECIPIENT, "RECIPIENT() mismatch");
        // setMinWithdrawalAmount / setWithdrawalNetwork: config sets min=0, network=L1(0).
        assertEq(_minWithdrawalAmount(vault), 0, "minWithdrawalAmount mismatch");
        assertEq(uint256(_withdrawalNetwork(vault)), 0, "withdrawalNetwork mismatch (expected L1)");
    }

    // ----- view helpers (low-level so a reverting getter is a value, not a test abort) -----

    function _version(address vault) internal view returns (string memory) {
        return abi.decode(_mustCall(vault, abi.encodeWithSignature("version()")), (string));
    }

    function _legacyRecipient(address vault) internal view returns (address) {
        return abi.decode(_mustCall(vault, abi.encodeWithSignature("RECIPIENT()")), (address));
    }

    function _storageRecipient(address vault) internal view returns (address) {
        return abi.decode(_mustCall(vault, abi.encodeWithSignature("recipient()")), (address));
    }

    function _minWithdrawalAmount(address vault) internal view returns (uint256) {
        return abi.decode(_mustCall(vault, abi.encodeWithSignature("minWithdrawalAmount()")), (uint256));
    }

    function _withdrawalNetwork(address vault) internal view returns (uint8) {
        return abi.decode(_mustCall(vault, abi.encodeWithSignature("withdrawalNetwork()")), (uint8));
    }

    /// @notice True iff the storage-backed `recipient()` getter exists (only on v1.6.0, not v1.3.1).
    function _storageRecipientReadable(address vault) internal view returns (bool ok) {
        (ok,) = vault.staticcall(abi.encodeWithSignature("recipient()"));
    }

    function _mustCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool ok, bytes memory ret) = target.staticcall(data);
        require(ok, "staticcall failed");
        return ret;
    }

    function _slice(bytes memory data, uint256 start, uint256 length) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }
}
