// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IntegrationBase} from "./IntegrationBase.t.sol";
import {IFeeSplitter} from "src/interfaces/IFeeSplitter.sol";
import {ISuperchainRevSharesCalculator} from "src/interfaces/ISuperchainRevSharesCalculator.sol";

/// @title RevSharePostTaskAssertionsTest
/// @notice Integration test for asserting Rev Share contract state after task execution.
///         This test does NOT execute the task simulation or relay L1->L2 messages.
///         It directly asserts the expected state on L2 chains after a real task execution.
///         The L1Withdrawer and calculator addresses are queried directly from the FeeSplitter
///         on-chain, making this test compatible with any deployment mechanism (CREATE2 or genesis).
/// @dev Required environment variables:
///      - RPC_URL: L2 RPC URL to create fork
///      - L1_RPC_URL: L1 RPC URL to create fork (for withdrawal relay tests)
///      - OP_RPC_URL: OP L2 RPC URL for L1→L2 relay tests
///      - OPTIMISM_PORTAL: Portal address for the chain
///      - L1_MESSENGER: L1CrossDomainMessenger address for the chain
///      - OP_L1_MESSENGER: OP L1CrossDomainMessenger address
///      - OP_PORTAL: OP Portal address where FeesDepositor deposits to
///      - FEES_DEPOSITOR_TARGET: Target address that FeesDepositor sends funds to on OP L2
///      - MIN_WITHDRAWAL_AMOUNT: Expected min withdrawal amount for L1Withdrawer (wei)
///      - L1_WITHDRAWAL_RECIPIENT: Expected L1 withdrawal recipient address
///      - WITHDRAWAL_GAS_LIMIT: Expected gas limit for withdrawals
///      - CHAIN_FEES_RECIPIENT: Expected chain fees recipient address
/// @dev Example command:
/// ```sh
/// RPC_URL="https://revshare-alpha-0.optimism.io" \
/// L1_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com" \
/// OP_RPC_URL="https://sepolia.optimism.io" \
/// OPTIMISM_PORTAL="0x176e57217e8824e26cd0f78cd6de2a0655feb675" \
/// L1_MESSENGER="0xb24a72a720e0ddec249379dc04bcb1a9c780c7c6" \
/// OP_L1_MESSENGER="0x58Cc85b8D04EA49cC6DBd3CbFFd00B4B8D6cb3ef" \
/// OP_PORTAL="0x16Fc5058F25648194471939df75CF27A2fdC48BC" \
/// FEES_DEPOSITOR_TARGET="0x7ca800c55ad9C745AC84FdeEfaf4522F4Df07577" \
/// MIN_WITHDRAWAL_AMOUNT="2000000000000000000" \
/// L1_WITHDRAWAL_RECIPIENT="0xed9B99a703BaD32AC96FDdc313c0652e379251Fd" \
/// WITHDRAWAL_GAS_LIMIT="800000" \
/// CHAIN_FEES_RECIPIENT="0x455A1115C97cb0E2b24B064C00a9E13872cC37ca" \
/// forge test --match-contract RevSharePostTaskAssertionsTest -vvv
/// ```
contract RevSharePostTaskAssertionsTest is IntegrationBase {
    // Fork ID
    uint256 internal _l2ForkId;

    // Chain configuration from env vars
    address internal _portal;
    address internal _l1Messenger;
    address internal _opL1Messenger;
    address internal _opPortal;
    address internal _feesDepositorTarget;

    // Expected values from env vars
    uint256 internal _expectedMinWithdrawalAmount;
    address internal _expectedL1WithdrawalRecipient;
    uint32 internal _expectedWithdrawalGasLimit;
    address internal _expectedChainFeesRecipient;

    // RevShare addresses discovered from on-chain state
    address internal _calculator;
    address internal _l1Withdrawer;

    // Flag to track if env vars are set
    bool internal _isEnabled;

    function setUp() public {
        // Read env vars with defaults to detect if they're set
        string memory rpcUrl = vm.envOr("RPC_URL", string(""));
        string memory l1RpcUrl = vm.envOr("L1_RPC_URL", string(""));
        string memory opRpcUrl = vm.envOr("OP_RPC_URL", string(""));
        _portal = vm.envOr("OPTIMISM_PORTAL", address(0));
        _l1Messenger = vm.envOr("L1_MESSENGER", address(0));
        _opL1Messenger = vm.envOr("OP_L1_MESSENGER", address(0));
        _opPortal = vm.envOr("OP_PORTAL", address(0));
        _feesDepositorTarget = vm.envOr("FEES_DEPOSITOR_TARGET", address(0));

        // Expected values to verify against on-chain state
        _expectedMinWithdrawalAmount = vm.envOr("MIN_WITHDRAWAL_AMOUNT", uint256(0));
        _expectedL1WithdrawalRecipient = vm.envOr("L1_WITHDRAWAL_RECIPIENT", address(0));
        _expectedWithdrawalGasLimit = uint32(vm.envOr("WITHDRAWAL_GAS_LIMIT", uint256(0)));
        _expectedChainFeesRecipient = vm.envOr("CHAIN_FEES_RECIPIENT", address(0));

        // Check if all required env vars are set (combined to avoid stack too deep)
        _isEnabled = bytes(rpcUrl).length > 0 && bytes(l1RpcUrl).length > 0 && bytes(opRpcUrl).length > 0
            && _portal != address(0) && _l1Messenger != address(0) && _opL1Messenger != address(0)
            && _opPortal != address(0) && _feesDepositorTarget != address(0) && _expectedMinWithdrawalAmount != 0
            && _expectedL1WithdrawalRecipient != address(0) && _expectedWithdrawalGasLimit != 0
            && _expectedChainFeesRecipient != address(0);

        if (_isEnabled) {
            _mainnetForkId = vm.createFork(l1RpcUrl);
            _opMainnetForkId = vm.createFork(opRpcUrl);
            _l2ForkId = vm.createFork(rpcUrl);

            // Query RevShare addresses from on-chain state
            vm.selectFork(_l2ForkId);
            _calculator = IFeeSplitter(FEE_SPLITTER).sharesCalculator();
            require(_calculator != address(0), "FeeSplitter calculator not set - RevShare not configured");

            _l1Withdrawer = address(ISuperchainRevSharesCalculator(_calculator).shareRecipient());
            require(_l1Withdrawer != address(0), "Calculator shareRecipient not set");
        }
    }

    /// @notice Assert the Rev Share contract state on the L2 chain
    function test_assertRevShareState() public {
        if (!_isEnabled) {
            vm.skip(true);
        }
        vm.selectFork(_l2ForkId);

        _assertL2State(
            _l1Withdrawer,
            _calculator,
            _expectedMinWithdrawalAmount,
            _expectedL1WithdrawalRecipient,
            _expectedWithdrawalGasLimit,
            _expectedChainFeesRecipient
        );
    }

    /// @notice Test the withdrawal flow on the L2 chain - tests both below and above threshold paths
    // Fund vaults so that:
    // - First disburse: share < minWithdrawalAmount (below threshold, no withdrawal)
    // - Second disburse: total >= minWithdrawalAmount (triggers withdrawal)
    function test_withdrawalFlow() public {
        if (!_isEnabled) {
            vm.skip(true);
        }

        // ==================== PART 1: Below threshold - no withdrawal ====================
        vm.selectFork(_l2ForkId);

        // Fund vaults to get ~half threshold as share
        // L1Withdrawer share = netRevenue * 15% = vaultFunding * 3 * 15 / 100 = vaultFunding * 45 / 100
        uint256 firstVaultFunding = (_expectedMinWithdrawalAmount * 100) / 90;
        _fundVaults(firstVaultFunding, _l2ForkId);

        // Warp time to allow disbursement
        vm.warp(block.timestamp + IFeeSplitter(FEE_SPLITTER).feeDisbursementInterval() + 1);

        // Record L1Withdrawer balance before
        uint256 l1WithdrawerBalanceBefore = _l1Withdrawer.balance;

        // Disburse fees - should NOT trigger withdrawal (below threshold)
        IFeeSplitter(FEE_SPLITTER).disburseFees();

        // Verify funds accumulated in L1Withdrawer (no withdrawal triggered)
        uint256 l1WithdrawerBalanceAfter = _l1Withdrawer.balance;
        uint256 expectedFirstShare = (firstVaultFunding * 3 * 15) / 100;
        assertEq(
            l1WithdrawerBalanceAfter - l1WithdrawerBalanceBefore,
            expectedFirstShare,
            "L1Withdrawer should have received expected share"
        );

        // ==================== PART 2: At threshold - withdrawal triggers ====================

        // Calculate how much more we need to reach the threshold
        uint256 remainingToThreshold = _expectedMinWithdrawalAmount - l1WithdrawerBalanceAfter;
        // Fund vaults to get at least the remaining amount as share
        // share = vaultFunding * 45 / 100, so vaultFunding = share * 100 / 45
        // Round up to ensure we exceed threshold: (a + b - 1) / b
        uint256 secondVaultFunding = ((remainingToThreshold * 100) + 44) / 45;
        _fundVaults(secondVaultFunding, _l2ForkId);

        // Warp time again
        vm.warp(block.timestamp + IFeeSplitter(FEE_SPLITTER).feeDisbursementInterval() + 1);

        // Calculate expected withdrawal amount (current balance + new share)
        // share = netRevenue * 15% = vaultFunding * 3 * 15 / 100
        uint256 secondShare = (secondVaultFunding * 3 * 15) / 100;
        uint256 expectedWithdrawalAmount = l1WithdrawerBalanceAfter + secondShare;

        _executeDisburseAndAssertWithdrawal(
            ChainConfig({
                l1ForkId: _mainnetForkId,
                l2ForkId: _l2ForkId,
                l1Withdrawer: _l1Withdrawer,
                l1WithdrawalRecipient: _expectedL1WithdrawalRecipient,
                expectedWithdrawalAmount: expectedWithdrawalAmount,
                portal: _portal,
                l1Messenger: _l1Messenger,
                withdrawalGasLimit: _expectedWithdrawalGasLimit
            }),
            OPConfig({
                opL2ForkId: _opMainnetForkId,
                opL1Messenger: _opL1Messenger,
                opPortal: _opPortal,
                feesDepositorTarget: _feesDepositorTarget
            })
        );
    }
}
