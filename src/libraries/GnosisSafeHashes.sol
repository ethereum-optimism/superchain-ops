// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {LibString} from "@solady/utils/LibString.sol";
import {JSONParserLib} from "@solady/utils/JSONParserLib.sol";
import {GnosisSafe} from "lib/safe-contracts/contracts/GnosisSafe.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

/// @title GnosisSafeHashes
/// @notice Library for calculating domain separators and message hashes for Gnosis Safe transactions
library GnosisSafeHashes {
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    // Safe transaction type hash
    bytes32 constant SAFE_TX_TYPEHASH = keccak256(
        "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    );

    // Define a struct for Safe transaction parameters
    struct SafeTx {
        address to;
        uint256 value;
        bytes32 dataHash; // Pre-hashed data
        uint8 operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address refundReceiver;
        uint256 nonce;
    }

    /// @notice Calculates the EIP-712 domain separator for a Safe
    /// @param _chainId The chain ID
    /// @param _safeAddress The address of the Safe contract
    /// @return domainSeparator_ The calculated domain separator
    function calculateDomainSeparator(uint256 _chainId, address _safeAddress)
        internal
        view
        returns (bytes32 domainSeparator_)
    {
        // Gnosis Safe deployments before 1.3.0 used this domain separator without the chainId
        if (isOldDomainSeparatorVersion(_safeAddress)) {
            domainSeparator_ = keccak256(abi.encode(keccak256("EIP712Domain(address verifyingContract)"), _safeAddress));
        } else {
            domainSeparator_ = keccak256(
                abi.encode(keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"), _chainId, _safeAddress)
            );
        }
    }

    /// @notice Calculates the EIP-712 message hash from calldata and nonce
    /// @param _callData The calldata containing the Safe transaction parameters
    /// @param _nonce The nonce to use for the transaction
    /// @return messageHash_ The calculated message hash
    function calculateMessageHashFromCalldata(bytes memory _callData, uint256 _nonce)
        internal
        pure
        returns (bytes32 messageHash_)
    {
        // Create and populate a SafeTx struct
        SafeTx memory _safeTx;

        // Skip the function selector (4 bytes)
        uint256 pos = 4;

        // Extract parameters directly from calldata
        _safeTx.to = address(uint160(readUint256(_callData, pos)));
        pos += 32;

        _safeTx.value = readUint256(_callData, pos);
        pos += 32;

        // Get data offset and extract the data
        uint256 dataOffset = readUint256(_callData, pos);
        uint256 dataPos = 4 + dataOffset;
        uint256 dataLen = readUint256(_callData, dataPos);

        // Extract data bytes
        bytes memory data = new bytes(dataLen);
        for (uint256 i = 0; i < dataLen; i++) {
            data[i] = _callData[dataPos + 32 + i];
        }

        // Hash the data
        _safeTx.dataHash = keccak256(data);

        // Continue extracting parameters
        pos += 32; // Move past data offset
        _safeTx.operation = uint8(readUint256(_callData, pos));
        pos += 32;

        _safeTx.safeTxGas = readUint256(_callData, pos);
        pos += 32;

        _safeTx.baseGas = readUint256(_callData, pos);
        pos += 32;

        _safeTx.gasPrice = readUint256(_callData, pos);
        pos += 32;

        _safeTx.gasToken = address(uint160(readUint256(_callData, pos)));
        pos += 32;

        _safeTx.refundReceiver = address(uint160(readUint256(_callData, pos)));

        // Set the nonce
        _safeTx.nonce = _nonce;

        // Calculate the message hash using the struct
        messageHash_ = keccak256(
            abi.encode(
                SAFE_TX_TYPEHASH,
                _safeTx.to,
                _safeTx.value,
                _safeTx.dataHash,
                _safeTx.operation,
                _safeTx.safeTxGas,
                _safeTx.baseGas,
                _safeTx.gasPrice,
                _safeTx.gasToken,
                _safeTx.refundReceiver,
                _safeTx.nonce
            )
        );
    }

    /// @notice Reads a uint256 from a bytes memory array at a given position.
    /// @param _data The bytes memory array.
    /// @param _pos The position in the array.
    /// @return result_ The uint256 value.
    function readUint256(bytes memory _data, uint256 _pos) internal pure returns (uint256 result_) {
        require(_pos + 32 <= _data.length, "CalculateSafeHashes: out of bounds");
        assembly {
            result_ := mload(add(add(_data, 32), _pos))
        }
    }

    // Helper function to get minimum of two values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Checks if the version is below 1.3.0. We are ignoring tags such as beta, rc, etc.
    /// @param _safeAddress The address of the Gnosis Safe contract
    /// @return isOldVersion_ True if the version is below 1.3.0, false otherwise
    function isOldDomainSeparatorVersion(address _safeAddress) internal view returns (bool isOldVersion_) {
        // Get the version from the Gnosis Safe contract
        GnosisSafe safe = GnosisSafe(payable(_safeAddress));
        string memory version = safe.VERSION();

        // Find positions of dots
        uint256 firstDot = LibString.indexOf(version, ".");
        require(firstDot != type(uint256).max, "GnosisSafeHashes: Invalid version format");

        uint256 secondDot = LibString.indexOf(version, ".", firstDot + 1);
        require(secondDot != type(uint256).max, "GnosisSafeHashes: Invalid version format");

        // Parse major and minor versions
        uint256 major = JSONParserLib.parseUint(LibString.slice(version, 0, firstDot));
        uint256 minor = JSONParserLib.parseUint(LibString.slice(version, firstDot + 1, secondDot - firstDot + 1));

        isOldVersion_ = (major < 1 || (major == 1 && minor < 3));
    }

    /// @notice Reads the result of a call to Safe.encodeTransactionData and returns the message hash.
    function getDomainAndMessageHashFromEncodedTransactionData(bytes memory _encodedTxData)
        internal
        pure
        returns (bytes32 domainSeparator_, bytes32 messageHash_)
    {
        require(_encodedTxData.length == 66, "GnosisSafeHashes: Invalid encoded transaction data length.");
        require(_encodedTxData[0] == bytes1(0x19), "GnosisSafeHashes: Expected prefix byte 0x19.");
        require(_encodedTxData[1] == bytes1(0x01), "GnosisSafeHashes: Expected prefix byte 0x01.");

        // Memory layout of a `bytes` array in Solidity:
        //   - The first 32 bytes store the array length (66 bytes here).
        //   - The actual data starts immediately after the length.
        // Our data structure is:
        //   [0x19][0x01][32-byte domainSeparator][32-byte messageHash]
        // The message hash begins at offset: 32 (skip length) + 34 = 66.
        assembly {
            // Domain separator starts after 2-byte prefix (offset 34 in bytes array)
            domainSeparator_ := mload(add(_encodedTxData, 34))
            // Message hash starts at offset 66 (after domain separator)
            messageHash_ := mload(add(_encodedTxData, 66))
        }
    }

    /// @notice Struct for a Safe transaction. Used as the EIP-712 hash struct.
    struct SafeTransaction {
        address to;
        uint256 value;
        bytes data;
        uint8 operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address refundReceiver;
        uint256 nonce;
    }

    /// @notice Generates a JSON string for the EIP-712 typed data. This string that is logged must be passed as an arg
    /// to cast e.g. 'cast wallet sign --ledger --data "$(forge script EIP712 --json | jq -r '.logs[0]')"'.
    function generateTypedDataJson(uint256 chainId, address verifyingContract, SafeTransaction memory safeTx)
        external
        pure
    {
        console.log(
            string.concat(
                "{\n",
                '  "types": {\n',
                '    "EIP712Domain": [\n',
                '      { "name": "chainId", "type": "uint256" }, \n',
                '      { "name": "verifyingContract", "type": "address" }\n',
                "    ],\n",
                '    "SafeTx": [\n',
                '      { "name": "to", "type": "address" },\n',
                '      { "name": "value", "type": "uint256" },\n',
                '      { "name": "data", "type": "bytes" },\n',
                '      { "name": "operation", "type": "uint8" },\n',
                '      { "name": "safeTxGas", "type": "uint256" },\n',
                '      { "name": "baseGas", "type": "uint256" },\n',
                '      { "name": "gasPrice", "type": "uint256" },\n',
                '      { "name": "gasToken", "type": "address" },\n',
                '      { "name": "refundReceiver", "type": "address" },\n',
                '      { "name": "nonce", "type": "uint256" }\n',
                "    ]\n",
                "  },\n",
                '  "primaryType": "SafeTx",\n',
                '  "domain": {\n',
                string.concat('    "chainId": ', vm.toString(chainId), ",\n"),
                string.concat('    "verifyingContract": "', vm.toString(verifyingContract), '"\n'),
                "  },\n",
                '  "message": {\n',
                string.concat('    "to": "', vm.toString(safeTx.to), '",\n'),
                string.concat('    "value": ', vm.toString(safeTx.value), ",\n"),
                string.concat('    "data": "', vm.toString(safeTx.data), '",\n'),
                string.concat('    "operation": ', vm.toString(uint256(safeTx.operation)), ",\n"),
                string.concat('    "safeTxGas": ', vm.toString(safeTx.safeTxGas), ",\n"),
                string.concat('    "baseGas": ', vm.toString(safeTx.baseGas), ",\n"),
                string.concat('    "gasPrice": ', vm.toString(safeTx.gasPrice), ",\n"),
                string.concat('    "gasToken": "', vm.toString(safeTx.gasToken), '",\n'),
                string.concat('    "refundReceiver": "', vm.toString(safeTx.refundReceiver), '",\n'),
                string.concat('    "nonce": ', vm.toString(safeTx.nonce), "\n"),
                "  }\n",
                "}\n"
            )
        );
    }
}
