// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {UpdateFeeVaultRecipient} from "src/template/UpdateFeeVaultRecipient.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

/// @title UpdateFeeVaultRecipientIntegrationTest
/// @notice Integration test that simulates the L1 task execution and replays the 3 deposit
///         transactions on a forked Arena-Z L2 to verify the fee vault recipient update end-to-end.
///
///         To run this test, start supersim or provide RPC URLs:
///         - L1 (Sepolia): default http://127.0.0.1:8545 or set SEPOLIA_RPC_URL
///         - L2 (Arena-Z): default https://testnet-rpc.arena-z.gg or set ARENA_Z_RPC_URL
///
///         Example:
///         forge test --match-test test_updateFeeVaultRecipient_integration -vvv
contract UpdateFeeVaultRecipientIntegrationTest is Test {
    event TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData);

    UpdateFeeVaultRecipient public template;

    uint256 internal sepoliaForkId;
    uint256 internal arenaZForkId;

    // Arena-Z Sepolia OptimismPortal on L1
    address internal constant ARENA_Z_PORTAL = 0x90FdCE6eFFF020605462150cdE42257193d1e558;

    // L2 fee vault predeploys
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;

    // Expected new recipient — baked into the pre-deployed implementations
    address internal constant NEW_RECIPIENT = 0xE75f598754A552841E65f43197C85028874A96a4;
    // Pre-deployed implementation addresses on Arena Z testnet
    address internal constant SEQ_IMPL = 0x1A4898C391a34E2C38B38A3D2CA4cEbF1BBA783e;
    address internal constant DEFAULT_IMPL = 0x8dCC1BbE83752DDB79df32D56B3f37758bBac7AE;

    // Config path
    string internal constant CONFIG_PATH = "src/tasks/sep/072-arena-z-fee-vault-update/config.toml";

    function setUp() public {
        // Create L1 fork (Sepolia)
        string memory sepoliaRpc = vm.envOr("SEPOLIA_RPC_URL", string(""));
        sepoliaForkId = vm.createFork(sepoliaRpc);

        // Create L2 fork (Arena-Z testnet)
        string memory arenaZRpc = vm.envOr("ARENA_Z_RPC_URL", string("https://testnet-rpc.arena-z.gg"));
        arenaZForkId = vm.createFork(arenaZRpc);

        // Deploy template on L1 fork
        vm.selectFork(sepoliaForkId);
        template = new UpdateFeeVaultRecipient();
    }

    /// @notice End-to-end test: simulate L1 task, replay deposits on L2, verify fee vault recipients.
    function test_updateFeeVaultRecipient_integration() public {
        // Step 1: Record logs during L1 simulation
        vm.selectFork(sepoliaForkId);
        vm.recordLogs();

        // Step 2: Execute task simulation on L1
        template.simulate(CONFIG_PATH);

        // Step 3: Get recorded logs and relay deposit transactions to L2
        Vm.Log[] memory allLogs = vm.getRecordedLogs();
        _relayDepositsToL2(allLogs);

        // Step 4: Assert L2 state after deposit execution
        vm.selectFork(arenaZForkId);
        _assertFeeVaultRecipients();
        _assertFeeVaultVersions();
    }

    /// @notice Relay all TransactionDeposited events from the Arena-Z portal to the L2 fork.
    function _relayDepositsToL2(Vm.Log[] memory allLogs) internal {
        vm.selectFork(arenaZForkId);

        bytes32 txDepositedSelector = keccak256("TransactionDeposited(address,address,uint256,bytes)");

        // Simulations emit events twice (dry-run + actual), take second half
        uint256 startIndex = allLogs.length / 2;

        uint256 txCount;
        uint256 successCount;

        for (uint256 i = startIndex; i < allLogs.length; i++) {
            if (allLogs[i].topics[0] != txDepositedSelector) continue;
            if (allLogs[i].emitter != ARENA_Z_PORTAL) continue;

            address from = address(uint160(uint256(allLogs[i].topics[1])));
            address to = address(uint160(uint256(allLogs[i].topics[2])));
            bytes memory opaqueData = abi.decode(allLogs[i].data, (bytes));

            // Parse opaqueData: value(32) + mint(32) + gasLimit(8) + isCreation(1) + data(...)
            uint256 value = uint256(bytes32(_slice(opaqueData, 0, 32)));
            uint64 gasLimit = uint64(bytes8(_slice(opaqueData, 64, 8)));
            bytes memory data = _slice(opaqueData, 73, opaqueData.length - 73);

            txCount++;

            vm.prank(from);
            (bool success,) = to.call{value: value, gas: gasLimit}(data);

            if (success) {
                successCount++;
                console2.log("Deposit tx", txCount, "succeeded");
            } else {
                console2.log("Deposit tx", txCount, "FAILED");
            }
        }

        console2.log("\n=== Deposit Relay Summary ===");
        console2.log("Total:", txCount);
        console2.log("Succeeded:", successCount);

        assertEq(txCount, 3, "Expected 3 deposit transactions");
        assertEq(successCount, 3, "All deposit transactions should succeed");
    }

    /// @notice Assert all 3 fee vaults now return the new recipient.
    function _assertFeeVaultRecipients() internal view {
        assertEq(_getRecipient(SEQUENCER_FEE_VAULT), NEW_RECIPIENT, "SequencerFeeVault recipient mismatch");
        assertEq(_getRecipient(BASE_FEE_VAULT), NEW_RECIPIENT, "BaseFeeVault recipient mismatch");
        assertEq(_getRecipient(L1_FEE_VAULT), NEW_RECIPIENT, "L1FeeVault recipient mismatch");
    }

    /// @notice Assert all 3 fee vaults are on version 1.5.0-beta.5.
    function _assertFeeVaultVersions() internal view {
        string memory expectedVersion = "1.5.0-beta.5";
        assertEq(_getVersion(SEQUENCER_FEE_VAULT), expectedVersion, "SequencerFeeVault version mismatch");
        assertEq(_getVersion(BASE_FEE_VAULT), expectedVersion, "BaseFeeVault version mismatch");
        assertEq(_getVersion(L1_FEE_VAULT), expectedVersion, "L1FeeVault version mismatch");
    }

    function _getRecipient(address vault) internal view returns (address) {
        (bool ok, bytes memory ret) = vault.staticcall(abi.encodeWithSignature("RECIPIENT()"));
        require(ok, "RECIPIENT() call failed");
        return abi.decode(ret, (address));
    }

    function _getVersion(address vault) internal view returns (string memory) {
        (bool ok, bytes memory ret) = vault.staticcall(abi.encodeWithSignature("version()"));
        require(ok, "version() call failed");
        return abi.decode(ret, (string));
    }

    function _slice(bytes memory data, uint256 start, uint256 length) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }
}
