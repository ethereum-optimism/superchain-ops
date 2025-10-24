// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

/// @title IntegrationBase
/// @notice Base contract for integration tests with L1->L2 deposit transaction replay functionality
abstract contract IntegrationBase is Test {
    /// @notice Replay all deposit transactions from L1 to L2
    /// @param _forkId The fork ID to switch to for L2 execution
    /// @param _isSimulate If true, only process the second half of logs to avoid duplicates.
    ///                    Task simulations emit events twice: once during the initial dry-run
    ///                    and once during the actual simulation. Taking the second half ensures
    ///                    we only process the final simulation results.
    function _relayAllMessages(uint256 _forkId, bool _isSimulate) internal {
        vm.selectFork(_forkId);

        console2.log("\n");
        console2.log("================================================================================");
        console2.log("=== Replaying Deposit Transactions on L2                                    ===");
        console2.log("=== Each transaction includes Tenderly simulation link                      ===");
        console2.log("=== Network is set to 10 (OP Mainnet) - adjust if testing on different L2  ===");
        console2.log("================================================================================");

        // Get logs from L1 execution
        Vm.Log[] memory _allLogs = vm.getRecordedLogs();

        // If this is a simulation, only take the second half of logs to avoid processing duplicates
        // Simulations emit events twice, so we skip the first half
        uint256 _startIndex = _isSimulate ? _allLogs.length / 2 : 0;
        uint256 _logsCount = _isSimulate ? _allLogs.length - _startIndex : _allLogs.length;

        Vm.Log[] memory _logs = new Vm.Log[](_logsCount);
        for (uint256 _i = 0; _i < _logsCount; _i++) {
            _logs[_i] = _allLogs[_startIndex + _i];
        }

        // Filter for TransactionDeposited events
        bytes32 _transactionDepositedHash = keccak256("TransactionDeposited(address,address,uint256,bytes)");

        uint256 _transactionCount;
        uint256 _successCount;
        uint256 _failureCount;

        for (uint256 _i = 0; _i < _logs.length; _i++) {
            // Check if this is a TransactionDeposited event
            if (_logs[_i].topics[0] == _transactionDepositedHash) {
                // Decode indexed parameters
                address _from = address(uint160(uint256(_logs[_i].topics[1])));
                address _to = address(uint160(uint256(_logs[_i].topics[2])));

                // Decode the opaqueData
                bytes memory _opaqueData = abi.decode(_logs[_i].data, (bytes));

                _transactionCount++;

                // Process and execute the transaction
                bool _success = _processDepositTransaction(_from, _to, _opaqueData, _transactionCount);

                if (_success) {
                    _successCount++;
                } else {
                    _failureCount++;
                }
            }
        }

        console2.log("\n=== Summary ===");
        console2.log("Total transactions:", _transactionCount);
        console2.log("Successful transactions:", _successCount);
        console2.log("Failed transactions:", _failureCount);

        // Assert all transactions succeeded
        assertEq(_failureCount, 0, "All deposit transactions should succeed");
        assertEq(_successCount, _transactionCount, "All transactions should succeed");
    }

    /// @notice Process and execute a deposit transaction
    function _processDepositTransaction(address _from, address _to, bytes memory _opaqueData, uint256 _txNumber)
        internal
        returns (bool)
    {
        // Extract value (bytes 0-31)
        uint256 _value = uint256(bytes32(_slice(_opaqueData, 0, 32)));

        // Extract gasLimit (bytes 64-71)
        uint64 _gasLimit = uint64(bytes8(_slice(_opaqueData, 64, 8)));

        // Extract data (bytes 73 onwards)
        bytes memory _data = _slice(_opaqueData, 73, _opaqueData.length - 73);

        // Print Tenderly simulation parameters
        _logTransactionDetails(_from, _to, _value, _gasLimit, _data, _txNumber);

        // Execute the transaction on L2 as if it came from the aliased address
        vm.prank(_from);
        (bool _success,) = _to.call{value: _value, gas: _gasLimit}(_data);

        return _success;
    }

    /// @notice Log transaction details and Tenderly link
    function _logTransactionDetails(
        address _from,
        address _to,
        uint256 _value,
        uint64 _gasLimit,
        bytes memory _data,
        uint256 _txNumber
    ) internal pure {
        if (_data.length >= 4) {
            bytes4 _selector;
            assembly {
                _selector := mload(add(_data, 32))
            }
        }

        // Generate Tenderly simulation link
        string memory _tenderlyLink = _generateTenderlyLink(_to, _from, uint256(_gasLimit), _value, _data);
        console2.log("\nTenderly Simulation Link for transaction #", _txNumber);
        console2.log(_tenderlyLink);
    }

    /// @notice Helper function to slice bytes
    function _slice(bytes memory _data, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        bytes memory _result = new bytes(_length);
        for (uint256 _i = 0; _i < _length; _i++) {
            _result[_i] = _data[_start + _i];
        }
        return _result;
    }

    /// @notice Generate Tenderly simulation link for L2 transaction
    function _generateTenderlyLink(
        address _contractAddress,
        address _from,
        uint256 _gas,
        uint256 _value,
        bytes memory _rawFunctionInput
    ) internal pure returns (string memory) {
        // Convert bytes to hex string
        string memory _calldataHex = _bytesToHexString(_rawFunctionInput);

        // Build the Tenderly URL
        // network=10 for OP Mainnet (change if testing on different L2)
        return string.concat(
            "https://dashboard.tenderly.co/TENDERLY_USERNAME/TENDERLY_PROJECT/simulator/new",
            "?network=10",
            "&contractAddress=0x",
            _toAsciiString(_contractAddress),
            "&from=0x",
            _toAsciiString(_from),
            "&gas=",
            vm.toString(_gas),
            "&value=",
            vm.toString(_value),
            "&rawFunctionInput=0x",
            _calldataHex
        );
    }

    /// @notice Convert address to lowercase hex string without 0x prefix
    function _toAsciiString(address _addr) internal pure returns (string memory) {
        bytes memory _s = new bytes(40);
        for (uint256 _i = 0; _i < 20; _i++) {
            bytes1 _b = bytes1(uint8(uint256(uint160(_addr)) / (2 ** (8 * (19 - _i)))));
            bytes1 _hi = bytes1(uint8(_b) / 16);
            bytes1 _lo = bytes1(uint8(_b) - 16 * uint8(_hi));
            _s[2 * _i] = _char(_hi);
            _s[2 * _i + 1] = _char(_lo);
        }
        return string(_s);
    }

    /// @notice Convert bytes to hex string without 0x prefix
    function _bytesToHexString(bytes memory _data) internal pure returns (string memory) {
        bytes memory _hexChars = "0123456789abcdef";
        bytes memory _result = new bytes(_data.length * 2);
        for (uint256 _i = 0; _i < _data.length; _i++) {
            _result[_i * 2] = _hexChars[uint8(_data[_i] >> 4)];
            _result[_i * 2 + 1] = _hexChars[uint8(_data[_i] & 0x0f)];
        }
        return string(_result);
    }

    /// @notice Convert nibble to hex character
    function _char(bytes1 _b) internal pure returns (bytes1) {
        if (uint8(_b) < 10) return bytes1(uint8(_b) + 0x30);
        else return bytes1(uint8(_b) + 0x57);
    }
}
