// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

/// @title IntegrationBase
/// @notice Base contract for integration tests with L1->L2 deposit transaction relay functionality
abstract contract IntegrationBase is Test {
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
    function _processDepositTransaction(address _from, address _to, bytes memory _opaqueData)
        internal
        returns (bool)
    {
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
}
