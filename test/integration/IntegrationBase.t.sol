// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {FeeSplitterSetup} from "src/libraries/FeeSplitterSetup.sol";
import {RevShareCommon} from "src/libraries/RevShareCommon.sol";
import {Utils} from "src/libraries/Utils.sol";
import {RevShareContractsUpgrader} from "src/RevShareContractsUpgrader.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {IFeeSplitter} from "src/interfaces/IFeeSplitter.sol";
import {IFeeVault} from "src/interfaces/IFeeVault.sol";
import {IL1Withdrawer} from "src/interfaces/IL1Withdrawer.sol";
import {ISuperchainRevSharesCalculator} from "src/interfaces/ISuperchainRevSharesCalculator.sol";

/// @title IntegrationBase
/// @notice Base contract for integration tests with L1->L2 deposit transaction relay functionality
abstract contract IntegrationBase is Test {
    // Event for testing
    event WithdrawalInitiated(address indexed recipient, uint256 amount);

    // Fork IDs
    uint256 internal _mainnetForkId;
    uint256 internal _opMainnetForkId;
    uint256 internal _inkMainnetForkId;
    uint256 internal _soneiumMainnetForkId;

    // Shared upgrader contract
    RevShareContractsUpgrader public revShareUpgrader;

    // L1 addresses
    address internal constant PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address internal constant OP_MAINNET_PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant INK_MAINNET_PORTAL = 0x5d66C1782664115999C47c9fA5cd031f495D3e4F;
    address internal constant SONEIUM_MAINNET_PORTAL = 0x88e529A6ccd302c948689Cd5156C83D4614FAE92;
    address internal constant REV_SHARE_UPGRADER_ADDRESS = 0x0000000000000000000000000000000000001337;

    // L2 predeploys (same across all OP Stack chains)
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address internal constant OPERATOR_FEE_VAULT = 0x420000000000000000000000000000000000001b;
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
    address internal constant FEE_SPLITTER = 0x420000000000000000000000000000000000002B;

    // Test configuration - Globals
    uint256 internal constant DEFAULT_MIN_WITHDRAWAL_AMOUNT = 2 ether;
    uint32 internal constant DEFAULT_WITHDRAWAL_GAS_LIMIT = 800000;
    address internal constant FEES_DEPOSITOR = 0xed9B99a703BaD32AC96FDdc313c0652e379251Fd;

    // Test configuration - OP Mainnet
    uint256 internal constant OP_MIN_WITHDRAWAL_AMOUNT = DEFAULT_MIN_WITHDRAWAL_AMOUNT;
    address internal constant OP_L1_WITHDRAWAL_RECIPIENT = FEES_DEPOSITOR;
    uint32 internal constant OP_WITHDRAWAL_GAS_LIMIT = DEFAULT_WITHDRAWAL_GAS_LIMIT;
    address internal constant OP_CHAIN_FEES_RECIPIENT = 0x16A27462B4D61BDD72CbBabd3E43e11791F7A28c;

    // Test configuration - Ink Mainnet
    uint256 internal constant INK_MIN_WITHDRAWAL_AMOUNT = DEFAULT_MIN_WITHDRAWAL_AMOUNT;
    address internal constant INK_L1_WITHDRAWAL_RECIPIENT = FEES_DEPOSITOR;
    uint32 internal constant INK_WITHDRAWAL_GAS_LIMIT = DEFAULT_WITHDRAWAL_GAS_LIMIT;
    address internal constant INK_CHAIN_FEES_RECIPIENT = 0x5f077b4c3509C2c192e50B6654d924Fcb8126A60;

    // Test configuration - Soneium Mainnet
    uint256 internal constant SONEIUM_MIN_WITHDRAWAL_AMOUNT = DEFAULT_MIN_WITHDRAWAL_AMOUNT;
    address internal constant SONEIUM_L1_WITHDRAWAL_RECIPIENT = FEES_DEPOSITOR;
    uint32 internal constant SONEIUM_WITHDRAWAL_GAS_LIMIT = DEFAULT_WITHDRAWAL_GAS_LIMIT;
    address internal constant SONEIUM_CHAIN_FEES_RECIPIENT = 0xF07b3169ffF67A8AECdBb18d9761AEeE34591112;

    bool internal constant IS_SIMULATE = true;
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
    /// @notice Fund all fee vaults with specified amount
    /// @param _amount Amount to fund each vault with
    /// @param _forkId Fork ID to execute on

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
    /// @param _forkId The fork ID of the chain to test
    /// @param _l1WithdrawalRecipient The expected recipient of the withdrawal
    /// @param _expectedWithdrawalAmount The expected withdrawal amount
    function _executeDisburseAndAssertWithdrawal(
        uint256 _forkId,
        address _l1WithdrawalRecipient,
        uint256 _expectedWithdrawalAmount
    ) internal {
        vm.selectFork(_forkId);
        vm.warp(block.timestamp + IFeeSplitter(FEE_SPLITTER).feeDisbursementInterval() + 1);

        vm.expectEmit(true, true, true, true);
        emit WithdrawalInitiated(_l1WithdrawalRecipient, _expectedWithdrawalAmount);
        IFeeSplitter(FEE_SPLITTER).disburseFees();
    }
}
