// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/console.sol";
import {GnosisSafe} from "lib/safe-contracts/contracts/GnosisSafe.sol";

/// @title GnosisSafeHashes
/// @notice Library for calculating domain separators and message hashes for Gnosis Safe transactions
library GnosisSafeHashes {
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
        pure
        returns (bytes32 domainSeparator_)
    {
        // TODO: Load the FoS address from the AddressRegistry
        if (_safeAddress == 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A) {
            // Foundation Operations Safe - Gnosis Safe 1.1.1
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
}
