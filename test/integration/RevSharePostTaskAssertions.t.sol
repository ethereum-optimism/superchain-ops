// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IntegrationBase} from "./IntegrationBase.t.sol";

/// @title RevSharePostTaskAssertionsTest
/// @notice Integration test for asserting Rev Share contract state after task execution.
///         This test does NOT execute the task simulation or relay L1->L2 messages.
///         It directly asserts the expected state on L2 chains after a real task execution.
/// @dev Required environment variables:
///      - RPC_URL: L2 RPC URL to create fork
///      - L1_RPC_URL: L1 RPC URL to create fork (for withdrawal relay tests)
///      - OP_MAINNET_RPC_URL: OP Mainnet L2 RPC URL (for L1→L2 relay tests, defaults to RPC_URL)
///      - OPTIMISM_PORTAL: Portal address for the chain
///      - L1_MESSENGER: L1CrossDomainMessenger address for the chain
///      - MIN_WITHDRAWAL_AMOUNT: Min withdrawal amount for L1Withdrawer
///      - L1_WITHDRAWAL_RECIPIENT: L1 withdrawal recipient address
///      - WITHDRAWAL_GAS_LIMIT: Gas limit for withdrawals
///      - CHAIN_FEES_RECIPIENT: Chain fees recipient address
/// @dev Example command:
/// ```sh
/// RPC_URL="https://mainnet.optimism.io" \
/// L1_RPC_URL="https://eth.llamarpc.com" \
/// OP_MAINNET_RPC_URL="https://mainnet.optimism.io" \
/// OPTIMISM_PORTAL="0xbEb5Fc579115071764c7423A4f12eDde41f106Ed" \
/// L1_MESSENGER="0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1" \
/// MIN_WITHDRAWAL_AMOUNT="2000000000000000000" \
/// L1_WITHDRAWAL_RECIPIENT="0xed9B99a703BaD32AC96FDdc313c0652e379251Fd" \
/// WITHDRAWAL_GAS_LIMIT="800000" \
/// CHAIN_FEES_RECIPIENT="0x16A27462B4D61BDD72CbBabd3E43e11791F7A28c" \
/// forge test --match-contract RevSharePostTaskAssertionsTest
/// ```
contract RevSharePostTaskAssertionsTest is IntegrationBase {
    // Fork ID
    uint256 internal _l2ForkId;

    // Chain configuration from env vars
    address internal _portal;
    address internal _l1Messenger;
    uint256 internal _minWithdrawalAmount;
    address internal _l1WithdrawalRecipient;
    uint32 internal _withdrawalGasLimit;
    address internal _chainFeesRecipient;

    // Flag to track if env vars are set
    bool internal _isEnabled;

    /// @notice Modifier to skip tests if required env vars are not set
    modifier onlyIfEnabled() {
        if (!_isEnabled) {
            vm.skip(true);
        }
        _;
    }

    function setUp() public {
        // Read env vars with defaults to detect if they're set
        string memory rpcUrl = vm.envOr("RPC_URL", string(""));
        string memory l1RpcUrl = vm.envOr("L1_RPC_URL", string(""));
        string memory opMainnetRpcUrl = vm.envOr("OP_MAINNET_RPC_URL", rpcUrl); // Defaults to RPC_URL
        _portal = vm.envOr("OPTIMISM_PORTAL", address(0));
        _l1Messenger = vm.envOr("L1_MESSENGER", address(0));
        _minWithdrawalAmount = vm.envOr("MIN_WITHDRAWAL_AMOUNT", uint256(0));
        _l1WithdrawalRecipient = vm.envOr("L1_WITHDRAWAL_RECIPIENT", address(0));
        _withdrawalGasLimit = uint32(vm.envOr("WITHDRAWAL_GAS_LIMIT", uint256(0)));
        _chainFeesRecipient = vm.envOr("CHAIN_FEES_RECIPIENT", address(0));

        // Check if all required env vars are set
        bool hasRpcUrl = bytes(rpcUrl).length > 0;
        bool hasL1RpcUrl = bytes(l1RpcUrl).length > 0;
        bool hasPortal = _portal != address(0);
        bool hasL1Messenger = _l1Messenger != address(0);
        bool hasL1WithdrawalRecipient = _l1WithdrawalRecipient != address(0);
        bool hasWithdrawalGasLimit = _withdrawalGasLimit != 0;
        bool hasChainFeesRecipient = _chainFeesRecipient != address(0);

        _isEnabled = hasRpcUrl && hasL1RpcUrl && hasPortal && hasL1Messenger && hasL1WithdrawalRecipient
            && hasWithdrawalGasLimit && hasChainFeesRecipient;

        if (_isEnabled) {
            _mainnetForkId = vm.createFork(l1RpcUrl);
            _opMainnetForkId = vm.createFork(opMainnetRpcUrl);
            _l2ForkId = vm.createFork(rpcUrl);
        }
    }

    /// @notice Assert the Rev Share contract state on the L2 chain
    function test_assertRevShareState() public onlyIfEnabled {
        vm.selectFork(_l2ForkId);

        address l1Withdrawer =
            _computeL1WithdrawerAddress(_minWithdrawalAmount, _l1WithdrawalRecipient, _withdrawalGasLimit);
        address revShareCalculator = _computeRevShareCalculatorAddress(l1Withdrawer, _chainFeesRecipient);

        _assertL2State(
            l1Withdrawer,
            revShareCalculator,
            _minWithdrawalAmount,
            _l1WithdrawalRecipient,
            _withdrawalGasLimit,
            _chainFeesRecipient
        );
    }

    /// @notice Test the withdrawal flow on the L2 chain
    function test_withdrawalFlow() public onlyIfEnabled {
        // Fund vaults
        _fundVaults(1 ether, _l2ForkId);

        // Compute L1Withdrawer address
        address l1Withdrawer =
            _computeL1WithdrawerAddress(_minWithdrawalAmount, _l1WithdrawalRecipient, _withdrawalGasLimit);

        // Disburse fees and assert withdrawal
        // Expected L1Withdrawer share = 3 ether * 15% = 0.45 ether
        // It is 3 ether instead of 4 because net revenue doesn't count L1FeeVault's balance
        // For details on the rev share calculation, check the SuperchainRevSharesCalculator contract.
        // https://github.com/ethereum-optimism/optimism/blob/f392d4b7e8bc5d1c8d38fcf19c8848764f8bee3b/packages/contracts-bedrock/src/L2/SuperchainRevSharesCalculator.sol#L67-L101
        uint256 expectedWithdrawalAmount = 0.45 ether;

        _executeDisburseAndAssertWithdrawal(
            _mainnetForkId,
            _l2ForkId,
            _opMainnetForkId,
            l1Withdrawer,
            _l1WithdrawalRecipient,
            expectedWithdrawalAmount,
            _portal,
            _l1Messenger,
            _withdrawalGasLimit
        );
    }
}
