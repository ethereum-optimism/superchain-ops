// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {IL1CrossDomainMessenger} from "@eth-optimism-bedrock/interfaces/L1/IL1CrossDomainMessenger.sol";
import {ICrossDomainMessenger} from "@eth-optimism-bedrock/interfaces/universal/ICrossDomainMessenger.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
import {FeeSplitterSetup} from "src/libraries/FeeSplitterSetup.sol";
import {RevShareCommon} from "src/libraries/RevShareCommon.sol";
import {Utils} from "src/libraries/Utils.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {IFeeSplitter} from "src/interfaces/IFeeSplitter.sol";
import {IFeeVault} from "src/interfaces/IFeeVault.sol";
import {IL1Withdrawer} from "src/interfaces/IL1Withdrawer.sol";
import {ISuperchainRevSharesCalculator} from "src/interfaces/ISuperchainRevSharesCalculator.sol";

/// @title IntegrationBase
/// @notice Base contract for integration tests with L1->L2 deposit transaction relay functionality
abstract contract IntegrationBase is Test {
    using stdStorage for StdStorage;
    // Events for testing

    event WithdrawalInitiated(address indexed recipient, uint256 amount);
    event TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData);

    // Fork IDs
    uint256 internal _mainnetForkId;
    uint256 internal _opMainnetForkId;
    uint256 internal _inkMainnetForkId;
    uint256 internal _soneiumMainnetForkId;

    // L1 addresses
    address internal constant OP_MAINNET_PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant INK_MAINNET_PORTAL = 0x5d66C1782664115999C47c9fA5cd031f495D3e4F;
    address internal constant SONEIUM_MAINNET_PORTAL = 0x88e529A6ccd302c948689Cd5156C83D4614FAE92;
    address internal constant OP_MAINNET_L1_MESSENGER = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    address internal constant INK_MAINNET_L1_MESSENGER = 0x69d3Cf86B2Bf1a9e99875B7e2D9B6a84426c171f;
    address internal constant SONEIUM_MAINNET_L1_MESSENGER = 0x9CF951E3F74B644e621b36Ca9cea147a78D4c39f;

    // FeesDepositor configuration (triggers deposit to OP Mainnet when balance >= threshold)
    uint256 internal constant FEES_DEPOSITOR_THRESHOLD = 2 ether;

    // OP Mainnet fees recipient (OPM multisig) - target for FeesDepositor deposits
    address internal constant OP_MAINNET_FEES_RECIPIENT = 0x16A27462B4D61BDD72CbBabd3E43e11791F7A28c;

    // Aliased address for L1→L2 message relay
    address internal immutable OP_ALIASED_L1_MESSENGER = AddressAliasHelper.applyL1ToL2Alias(OP_MAINNET_L1_MESSENGER);

    // Simulation flag for task execution
    bool internal constant IS_SIMULATE = true;

    // L2 predeploys (same across all OP Stack chains)
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address internal constant OPERATOR_FEE_VAULT = 0x420000000000000000000000000000000000001b;
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
    address internal constant FEE_SPLITTER = 0x420000000000000000000000000000000000002B;
    address internal constant L2_CROSS_DOMAIN_MESSENGER = 0x4200000000000000000000000000000000000007;

    // Default L2 sender address
    address internal constant DEFAULT_L2_SENDER = 0x000000000000000000000000000000000000dEaD;

    // Extra gas buffer added to the minimum gas limit for the relayMessage function
    uint64 internal constant RELAY_GAS_OVERHEAD = 700_000;

    // Counter for unique L1→L2 message nonces (to avoid collisions on forks)
    uint240 internal _l1ToL2NonceCounter;

    // L2 chain configuration struct
    struct L2ChainConfig {
        uint256 forkId;
        address portal;
        address l1Messenger;
        uint256 minWithdrawalAmount;
        address l1WithdrawalRecipient;
        uint32 withdrawalGasLimit;
        address chainFeesRecipient;
        string name;
    }

    // Array to store all L2 chain configurations
    L2ChainConfig[] internal l2Chains;

    /// @notice Relay all deposit transactions from L1 to multiple L2s
    /// @param _forkIds Array of fork IDs for each L2 chain
    /// @param _isSimulate If true, only process the second half of logs to avoid duplicates.
    ///                    Task simulations emit events twice: once during the initial dry-run
    ///                    and once during the actual simulation. Taking the second half ensures
    ///                    we only process the final simulation results.
    /// @param _portals Array of Portal addresses corresponding to each fork.
    ///                 Only events emitted by each portal will be relayed on its corresponding L2.
    function _relayAllMessages(uint256[] memory _forkIds, bool _isSimulate, address[] memory _portals) internal {
        require(_forkIds.length == _portals.length, "Fork IDs and portals length mismatch");

        // Get logs from L1 execution (currently active fork should be L1)
        Vm.Log[] memory _allLogs = vm.getRecordedLogs();

        // Process each L2 chain
        for (uint256 _chainIdx; _chainIdx < _forkIds.length; _chainIdx++) {
            _relayMessagesForChain(_allLogs, _forkIds[_chainIdx], _isSimulate, _portals[_chainIdx]);
        }
    }

    /// @notice Relay deposit transactions for a single L2 chain
    /// @param _allLogs All recorded logs from L1 execution
    /// @param _forkId The fork ID to switch to for L2 execution
    /// @param _isSimulate If true, only process the second half of logs
    /// @param _portal The Portal address to filter events by
    function _relayMessagesForChain(Vm.Log[] memory _allLogs, uint256 _forkId, bool _isSimulate, address _portal)
        internal
    {
        // Switch to L2 fork for execution
        vm.selectFork(_forkId);

        console2.log("\n");
        console2.log("================================================================================");
        console2.log("=== Relaying Deposit Transactions on L2                                    ===");
        console2.log("=== Portal:", _portal);
        console2.log("=== Network is set to", block.chainid);
        console2.log("================================================================================");

        // If this is a simulation, only take the second half of logs to avoid processing duplicates
        // Simulations emit events twice, so we skip the first half
        uint256 _startIndex = _isSimulate ? _allLogs.length / 2 : 0;
        uint256 _logsCount = _isSimulate ? _allLogs.length - _startIndex : _allLogs.length;

        Vm.Log[] memory _logs = new Vm.Log[](_logsCount);
        for (uint256 _i; _i < _logsCount; _i++) {
            _logs[_i] = _allLogs[_startIndex + _i];
        }

        // Filter for TransactionDeposited events
        bytes32 _transactionDepositedHash = keccak256("TransactionDeposited(address,address,uint256,bytes)");

        uint256 _transactionCount;
        uint256 _successCount;
        uint256 _failureCount;

        for (uint256 _i; _i < _logs.length; _i++) {
            // Check if this is a TransactionDeposited event AND it was emitted by the specified portal
            if (_logs[_i].topics[0] == _transactionDepositedHash && _logs[_i].emitter == _portal) {
                // Decode indexed parameters
                address _from = address(uint160(uint256(_logs[_i].topics[1])));
                address _to = address(uint160(uint256(_logs[_i].topics[2])));

                // Decode the opaqueData
                bytes memory _opaqueData = abi.decode(_logs[_i].data, (bytes));

                _transactionCount++;

                // Process and execute the transaction
                bool _success = _processDepositTransaction(_from, _to, _opaqueData);

                if (_success) {
                    _successCount++;
                } else {
                    _failureCount++;
                }
            }
        }

        console2.log("\n=== Summary ===");
        console2.log("Total transactions processed:", _transactionCount);
        console2.log("Successful transactions:", _successCount);
        console2.log("Failed transactions:", _failureCount);

        // Assert all transactions succeeded
        assertEq(_failureCount, 0, "All deposit transactions should succeed");
        assertEq(_successCount, _transactionCount, "All transactions should succeed");
    }

    /// @notice Process and execute a deposit transaction
    function _processDepositTransaction(address _from, address _to, bytes memory _opaqueData) internal returns (bool) {
        // Extract value (bytes 0-31)
        uint256 _value = uint256(bytes32(_slice(_opaqueData, 0, 32)));

        // Extract gasLimit (bytes 64-71)
        uint64 _gasLimit = uint64(bytes8(_slice(_opaqueData, 64, 8)));

        // Extract data (bytes 73 onwards)
        bytes memory _data = _slice(_opaqueData, 73, _opaqueData.length - 73);

        // Execute the transaction on L2 as if it came from the aliased address
        vm.prank(_from);
        (bool _success,) = _to.call{value: _value, gas: _gasLimit}(_data);

        return _success;
    }

    /// @notice Helper function to slice bytes
    function _slice(bytes memory _data, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        bytes memory _result = new bytes(_length);
        for (uint256 _i; _i < _length; _i++) {
            _result[_i] = _data[_start + _i];
        }
        return _result;
    }

    /// @notice Compute deterministic L1Withdrawer address using CREATE2
    function _computeL1WithdrawerAddress(uint256 _minWithdrawalAmount, address _recipient, uint32 _gasLimit)
        internal
        pure
        returns (address)
    {
        bytes memory _initCode = bytes.concat(
            FeeSplitterSetup.l1WithdrawerCreationCode, abi.encode(_minWithdrawalAmount, _recipient, _gasLimit)
        );
        bytes32 _salt = RevShareCommon.getSalt("L1Withdrawer");
        return Utils.getCreate2Address(_salt, _initCode, RevShareCommon.CREATE2_DEPLOYER);
    }

    /// @notice Compute deterministic RevShareCalculator address using CREATE2
    function _computeRevShareCalculatorAddress(address _l1Withdrawer, address _chainFeesRecipient)
        internal
        pure
        returns (address)
    {
        bytes memory _initCode = bytes.concat(
            FeeSplitterSetup.scRevShareCalculatorCreationCode, abi.encode(_l1Withdrawer, _chainFeesRecipient)
        );
        bytes32 _salt = RevShareCommon.getSalt("SCRevShareCalculator");
        return Utils.getCreate2Address(_salt, _initCode, RevShareCommon.CREATE2_DEPLOYER);
    }

    /// @notice Fund all fee vaults with a specified amount
    /// @param _amount The amount to fund each vault with
    /// @param _forkId The fork ID of the chain to fund
    function _fundVaults(uint256 _amount, uint256 _forkId) internal {
        vm.selectFork(_forkId);
        vm.deal(SEQUENCER_FEE_VAULT, _amount);
        vm.deal(OPERATOR_FEE_VAULT, _amount);
        vm.deal(BASE_FEE_VAULT, _amount);
        vm.deal(L1_FEE_VAULT, _amount);
    }

    /// @notice Assert the state of all L2 contracts after upgrade
    /// @param _l1Withdrawer Expected L1Withdrawer address
    /// @param _revShareCalculator Expected RevShareCalculator address
    /// @param _minWithdrawalAmount Expected minimum withdrawal amount for L1Withdrawer
    /// @param _l1Recipient Expected recipient address for L1Withdrawer
    /// @param _gasLimit Expected gas limit for L1Withdrawer
    /// @param _chainFeesRecipient Expected chain fees recipient (remainder recipient)
    function _assertL2State(
        address _l1Withdrawer,
        address _revShareCalculator,
        uint256 _minWithdrawalAmount,
        address _l1Recipient,
        uint32 _gasLimit,
        address _chainFeesRecipient
    ) internal view {
        // L1Withdrawer: check configuration
        assertEq(
            IL1Withdrawer(_l1Withdrawer).minWithdrawalAmount(),
            _minWithdrawalAmount,
            "L1Withdrawer minWithdrawalAmount mismatch"
        );
        assertEq(IL1Withdrawer(_l1Withdrawer).recipient(), _l1Recipient, "L1Withdrawer recipient mismatch");
        assertEq(IL1Withdrawer(_l1Withdrawer).withdrawalGasLimit(), _gasLimit, "L1Withdrawer gasLimit mismatch");

        // Rev Share Calculator: check it's linked correctly
        assertEq(
            ISuperchainRevSharesCalculator(_revShareCalculator).shareRecipient(),
            _l1Withdrawer,
            "Calculator shareRecipient should be L1Withdrawer"
        );
        assertEq(
            ISuperchainRevSharesCalculator(_revShareCalculator).remainderRecipient(),
            _chainFeesRecipient,
            "Calculator remainderRecipient mismatch"
        );

        // Fee Splitter: check calculator is set
        assertEq(
            IFeeSplitter(FEE_SPLITTER).sharesCalculator(),
            _revShareCalculator,
            "FeeSplitter calculator should be set to RevShareCalculator"
        );

        // Vaults: recipient should be fee splitter, withdrawal network should be L2, min withdrawal amount 0
        _assertFeeVaultsState();
    }

    /// @notice Assert the configuration of all fee vaults
    function _assertFeeVaultsState() internal view {
        _assertVaultGetters(SEQUENCER_FEE_VAULT, FEE_SPLITTER, IFeeVault.WithdrawalNetwork.L2, 0);
        _assertVaultGetters(OPERATOR_FEE_VAULT, FEE_SPLITTER, IFeeVault.WithdrawalNetwork.L2, 0);
        _assertVaultGetters(BASE_FEE_VAULT, FEE_SPLITTER, IFeeVault.WithdrawalNetwork.L2, 0);
        _assertVaultGetters(L1_FEE_VAULT, FEE_SPLITTER, IFeeVault.WithdrawalNetwork.L2, 0);
    }

    /// @notice Assert the configuration of a single fee vault
    /// @param _vault The address of the fee vault
    /// @param _recipient The expected recipient of the fee vault
    /// @param _withdrawalNetwork The expected withdrawal network
    /// @param _minWithdrawalAmount The expected minimum withdrawal amount
    /// @dev Ensures both the legacy and the new getters return the same value
    function _assertVaultGetters(
        address _vault,
        address _recipient,
        IFeeVault.WithdrawalNetwork _withdrawalNetwork,
        uint256 _minWithdrawalAmount
    ) internal view {
        // Check new getters
        assertEq(IFeeVault(_vault).recipient(), _recipient, "Vault recipient mismatch");
        assertEq(
            uint256(IFeeVault(_vault).withdrawalNetwork()),
            uint256(_withdrawalNetwork),
            "Vault withdrawalNetwork mismatch"
        );
        assertEq(IFeeVault(_vault).minWithdrawalAmount(), _minWithdrawalAmount, "Vault minWithdrawalAmount mismatch");

        // Check legacy getters (should return same values)
        assertEq(IFeeVault(_vault).RECIPIENT(), _recipient, "Vault RECIPIENT (legacy) mismatch");
        assertEq(
            uint256(IFeeVault(_vault).WITHDRAWAL_NETWORK()),
            uint256(_withdrawalNetwork),
            "Vault WITHDRAWAL_NETWORK (legacy) mismatch"
        );
        assertEq(
            IFeeVault(_vault).MIN_WITHDRAWAL_AMOUNT(),
            _minWithdrawalAmount,
            "Vault MIN_WITHDRAWAL_AMOUNT (legacy) mismatch"
        );
    }

    /// @notice Execute disburseFees and assert that it triggers a withdrawal with the expected amount
    /// @param _l1ForkId The L1 fork ID
    /// @param _forkId The fork ID of the L2 chain to test
    /// @param _opL2ForkId The OP Mainnet L2 fork ID (for relaying L1→L2 deposits)
    /// @param _l1Withdrawer The L1Withdrawer address that emits the WithdrawalInitiated event
    /// @param _l1WithdrawalRecipient The expected recipient of the withdrawal
    /// @param _expectedWithdrawalAmount The expected withdrawal amount
    /// @param _portal The OptimismPortal address for this L2 chain
    /// @param _l1Messenger The L1CrossDomainMessenger address for this L2 chain
    /// @param _withdrawalGasLimit The gas limit used for L1 withdrawals
    function _executeDisburseAndAssertWithdrawal(
        uint256 _l1ForkId,
        uint256 _forkId,
        uint256 _opL2ForkId,
        address _l1Withdrawer,
        address _l1WithdrawalRecipient,
        uint256 _expectedWithdrawalAmount,
        address _portal,
        address _l1Messenger,
        uint32 _withdrawalGasLimit
    ) internal {
        vm.selectFork(_forkId);
        vm.warp(block.timestamp + IFeeSplitter(FEE_SPLITTER).feeDisbursementInterval() + 1);

        vm.expectEmit(true, true, true, true, _l1Withdrawer);
        emit WithdrawalInitiated(_l1WithdrawalRecipient, _expectedWithdrawalAmount);
        IFeeSplitter(FEE_SPLITTER).disburseFees();

        // Relay the withdrawal message to L1
        vm.selectFork(_l1ForkId);

        if (_expectedWithdrawalAmount >= FEES_DEPOSITOR_THRESHOLD) {
            // Expect TransactionDeposited event from OP Mainnet Portal
            // Note: FeesDepositor calls L1CrossDomainMessenger.sendMessage(), which calls OptimismPortal.depositTransaction()
            // The 'from' address in TransactionDeposited is the aliased L1CrossDomainMessenger (not the FeesDepositor)
            vm.expectEmit(true, true, true, false, OP_MAINNET_PORTAL);
            emit TransactionDeposited(
                OP_ALIASED_L1_MESSENGER, // aliased L1CrossDomainMessenger (caller of depositTransaction)
                L2_CROSS_DOMAIN_MESSENGER, // L2 CrossDomainMessenger
                0,
                ""
            );

            _relayL2ToL1Message(
                _portal,
                _l1Messenger,
                _l1Withdrawer, // sender on L2
                _l1WithdrawalRecipient, // target on L1
                _expectedWithdrawalAmount, // value
                _withdrawalGasLimit, // minGasLimit
                "" // data (empty for ETH transfer)
            );

            // Now relay the deposit from L1 to OP Mainnet L2
            vm.selectFork(_opL2ForkId);

            uint256 recipientBalanceBefore = OP_MAINNET_FEES_RECIPIENT.balance;

            // Relay the L1→L2 message (simple ETH transfer to OPM multisig)
            _relayL1ToL2Message(
                OP_ALIASED_L1_MESSENGER,
                _l1WithdrawalRecipient, // sender (FeesDepositor)
                OP_MAINNET_FEES_RECIPIENT, // target (OPM multisig)
                _expectedWithdrawalAmount,
                200_000, // gas limit for simple ETH transfer
                "" // empty data for ETH transfer
            );

            uint256 recipientBalanceAfter = OP_MAINNET_FEES_RECIPIENT.balance;
            assertEq(
                recipientBalanceAfter - recipientBalanceBefore,
                _expectedWithdrawalAmount,
                "OP Mainnet fees recipient should receive the withdrawal amount"
            );
        } else {
            // FeesDepositor holds the ETH (below threshold)
            uint256 recipientBalanceBefore = _l1WithdrawalRecipient.balance;

            _relayL2ToL1Message(
                _portal,
                _l1Messenger,
                _l1Withdrawer, // sender on L2
                _l1WithdrawalRecipient, // target on L1
                _expectedWithdrawalAmount, // value
                _withdrawalGasLimit, // minGasLimit
                "" // data (empty for ETH transfer)
            );

            uint256 recipientBalanceAfter = _l1WithdrawalRecipient.balance;
            assertEq(
                recipientBalanceAfter - recipientBalanceBefore,
                _expectedWithdrawalAmount,
                "L1 recipient should receive the withdrawal amount"
            );
        }
    }

    /// @notice Relay a message from L2 to L1 via the CrossDomainMessenger
    /// @dev This simulates the L2->L1 message relay by:
    ///      1. Setting the portal's l2Sender to the L2CrossDomainMessenger
    ///      2. Calling relayMessage on the L1CrossDomainMessenger from the portal
    ///      3. Resetting the l2Sender back to the default value
    /// @param _portal The OptimismPortal address
    /// @param _l1Messenger The L1CrossDomainMessenger address
    /// @param _sender The sender address on L2
    /// @param _target The target address on L1
    /// @param _value The ETH value to send
    /// @param _minGasLimit The minimum gas limit for the message
    /// @param _data The message data
    function _relayL2ToL1Message(
        address _portal,
        address _l1Messenger,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes memory _data
    ) internal {
        // Get the message nonce from the L1 messenger
        uint256 _messageNonce = IL1CrossDomainMessenger(_l1Messenger).messageNonce();

        // Set the l2Sender on the portal to the L2CrossDomainMessenger
        // This is required for the L1CrossDomainMessenger to accept the message
        stdstore.target(_portal).sig("l2Sender()").checked_write(L2_CROSS_DOMAIN_MESSENGER);

        // Deal ETH to the portal so it can send value with the message
        vm.deal(_portal, _value);

        // Call relayMessage from the portal with the ETH value
        vm.prank(_portal);
        IL1CrossDomainMessenger(_l1Messenger).relayMessage{gas: _minGasLimit + RELAY_GAS_OVERHEAD, value: _value}(
            _messageNonce, _sender, _target, _value, _minGasLimit, _data
        );

        // Reset the l2Sender back to the default value
        stdstore.target(_portal).sig("l2Sender()").checked_write(DEFAULT_L2_SENDER);
    }

    /// @notice Relay a message from L1 to L2 via the CrossDomainMessenger
    /// @dev This simulates the L1->L2 message relay by calling relayMessage on the L2CrossDomainMessenger.
    ///      Uses a unique nonce based on block.timestamp to avoid collisions with already-relayed messages on forks.
    /// @param _aliasedL1Messenger The aliased L1 messenger address (sender on L2)
    /// @param _sender The original sender on L1
    /// @param _target The target address on L2
    /// @param _value The ETH value to send
    /// @param _minGasLimit The minimum gas limit for the message
    /// @param _data The message data
    function _relayL1ToL2Message(
        address _aliasedL1Messenger,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes memory _data
    ) internal {
        // Use a unique nonce to avoid "message already relayed" errors on forked networks.
        // The nonce format is: version (16 bits) | nonce (240 bits)
        // Version 1 is used for L1->L2 messages. We combine block.timestamp with a counter for uniqueness.
        _l1ToL2NonceCounter++;
        uint256 _messageNonce =
            (uint256(1) << 240) | uint240(uint256(keccak256(abi.encode(block.timestamp, _l1ToL2NonceCounter))));
        vm.deal(_aliasedL1Messenger, _value);
        vm.prank(_aliasedL1Messenger);
        // OP adds some extra gas for the relayMessage logic
        ICrossDomainMessenger(L2_CROSS_DOMAIN_MESSENGER).relayMessage{
            gas: _minGasLimit + RELAY_GAS_OVERHEAD,
            value: _value
        }(_messageNonce, _sender, _target, _value, _minGasLimit, _data);
    }
}
