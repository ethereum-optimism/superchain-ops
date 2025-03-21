// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";

contract GnosisSafeHashes_Test is Test {
    using GnosisSafeHashes for bytes;

    /// @notice Test with valid input. The encoded data is constructed as:
    /// [0x19, 0x01, 32 bytes domain separator (zeros), 32 bytes message hash].
    function testGetMessageHashFromEncodedTransactionData_ValidInput() public pure {
        bytes memory encodedTxData = abi.encodePacked(
            bytes2(0x1901),
            bytes32(0), // Domain separator (dummy value)
            bytes32(hex"000000000000000000000000000000000000000000000000000000000000abcd")
        );
        bytes32 expectedHash = bytes32(hex"000000000000000000000000000000000000000000000000000000000000abcd");

        bytes32 result = encodedTxData.getMessageHashFromEncodedTransactionData();
        assertEq(result, expectedHash, "Message hash should match the last 32 bytes");
    }

    /// @notice Test where the message hash is all zeros.
    function testGetMessageHashFromEncodedTransactionData_AllZeros() public pure {
        bytes memory encodedTxData = abi.encodePacked(bytes2(0x1901), bytes32(0), bytes32(0));
        bytes32 expectedHash = bytes32(0);

        bytes32 result = encodedTxData.getMessageHashFromEncodedTransactionData();
        assertEq(result, expectedHash, "Message hash should be all zeros");
    }

    function testGetMessageHashFromEncodedTransactionData_MaxUint256() public pure {
        bytes memory encodedTxData = abi.encodePacked(bytes2(0x1901), bytes32(0), bytes32(type(uint256).max));
        bytes32 expectedHash = bytes32(type(uint256).max);

        bytes32 result = encodedTxData.getMessageHashFromEncodedTransactionData();
        assertEq(result, expectedHash, "Message hash should be the max uint256");
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testGetMessageHashFromEncodedTransactionData_TooShort() public {
        // Only 6 bytes (too short)
        bytes memory encodedTxData = hex"1901deadbeef";
        vm.expectRevert("GnosisSafeHashes: Invalid encoded transaction data length.");
        encodedTxData.getMessageHashFromEncodedTransactionData();
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testGetMessageHashFromEncodedTransactionData_TooLong() public {
        // 67 bytes (too long)
        bytes memory encodedTxData = new bytes(67);
        vm.expectRevert("GnosisSafeHashes: Invalid encoded transaction data length.");
        encodedTxData.getMessageHashFromEncodedTransactionData();
    }

    function testGetMessageHashFromEncodedTransactionData_FuzzTest(bytes32 randomHash) public pure {
        bytes memory encodedTxData = abi.encodePacked(bytes2(0x1901), bytes32(0), randomHash);
        bytes32 result = encodedTxData.getMessageHashFromEncodedTransactionData();
        assertEq(result, randomHash, "Message hash should match the input random hash");
    }
}
