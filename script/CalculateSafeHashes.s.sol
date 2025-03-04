// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {GnosisSafe} from "lib/safe-contracts/contracts/GnosisSafe.sol";

contract CalculateSafeHashes is Script {
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

    function run() external view {
        string memory filePath = vm.envOr("PAYLOAD_FILE", string("tenderly_payload.json"));

        // Check if file exists
        try vm.readFile(filePath) {
            // File exists, proceed
        } catch {
            console.log("\x1B[33m[WARN]\x1B[0m CalculateSafeHashes: File not found:", filePath);
            return;
        }

        // Parse JSON payload
        string memory json = vm.readFile(filePath);

        // Use specialized parsers for each data type
        string memory inputHex = vm.parseJsonString(json, ".input");
        uint256 chainId = vm.parseJsonUint(json, ".network_id");
        address payable safeAddress = payable(vm.parseJsonAddress(json, ".to"));

        // Get nonce from storage or contract call
        uint256 nonce;
        string memory storagePath = string(
            abi.encodePacked(
                ".state_objects.",
                vm.toString(safeAddress),
                ".storage.0x0000000000000000000000000000000000000000000000000000000000000005"
            )
        );

        try vm.parseJsonString(json, storagePath) returns (string memory nonceHex) {
            nonce = uint256(vm.parseBytes32(nonceHex));
        } catch {
            // Try to get nonce from contract call
            try GnosisSafe(safeAddress).nonce() returns (uint256 n) {
                nonce = n;
            } catch {
                console.log("\x1B[33m[WARN]\x1B[0m CalculateSafeHashes: Could not determine nonce, using 0");
            }
        }

        // Convert hex string to bytes
        bytes memory callData = vm.parseBytes(inputHex);

        // Extract function selector
        bytes4 selector;
        assembly {
            // Load first 4 bytes (function selector)
            selector := mload(add(add(callData, 32), 0))
        }

        if (
            selector
                != bytes4(
                    keccak256("execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)")
                )
        ) {
            console.log("\x1B[33m[WARN]\x1B[0m CalculateSafeHashes: Input is not an execTransaction call");
            return;
        }

        // Calculate domain separator
        bytes32 domainSeparator = calculateDomainSeparator(chainId, safeAddress);

        // Calculate message hash
        bytes32 messageHash = calculateMessageHashFromCalldata(callData, nonce);

        // Output results
        console.log("\n\n-------- Domain Separator and Message Hashes from Payload --------");
        console.log("Domain Separator:", vm.toString(domainSeparator));
        console.log("Message Hash:", vm.toString(messageHash));
    }

    /// @notice Calculates the EIP-712 domain separator for a Safe
    /// @param _chainId The chain ID
    /// @param _safeAddress The address of the Safe contract
    /// @return domainSeparator_ The calculated domain separator
    function calculateDomainSeparator(uint256 _chainId, address _safeAddress)
        internal
        pure
        returns (bytes32 domainSeparator_)
    {
        domainSeparator_ = keccak256(
            abi.encode(keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"), _chainId, _safeAddress)
        );
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
}
