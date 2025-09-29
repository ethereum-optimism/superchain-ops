// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {LibString} from "@solady/utils/LibString.sol";
import {JSONParserLib} from "@solady/utils/JSONParserLib.sol";
import {GnosisSafe} from "lib/safe-contracts/contracts/GnosisSafe.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";

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
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
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
    function getDomainAndMessageHashFromDataToSign(bytes memory _dataToSign)
        internal
        pure
        returns (bytes32 domainSeparator_, bytes32 messageHash_)
    {
        // If it looks like 0x1901-prefixed encoded bytes (66 bytes total), decode directly.
        if (_dataToSign.length == 66 && _dataToSign[0] == bytes1(0x19) && _dataToSign[1] == bytes1(0x01)) {
            // Memory layout of a `bytes` array in Solidity:
            //   - The first 32 bytes store the array length (66 bytes here).
            //   - The actual data starts immediately after the length.
            // Our data structure is:
            //   [0x19][0x01][32-byte domainSeparator][32-byte messageHash]
            // The message hash begins at offset: 32 (skip length) + 34 = 66.
            assembly {
                domainSeparator_ := mload(add(_dataToSign, 34))
                messageHash_ := mload(add(_dataToSign, 66))
            }
            return (domainSeparator_, messageHash_);
        }
        // Otherwise, assume EIP-712 JSON produced by encodeEIP712Json and compute from JSON.
        return getDomainAndMessageHashFromEip712Json(_dataToSign);
    }

    /// @notice Computes domain separator and message hash from an EIP-712 JSON payload produced by encodeEIP712Json.
    /// @dev This mirrors the Safe EIP-712 encoding: dynamic types such as bytes are hashed before struct encoding.
    function getDomainAndMessageHashFromEip712Json(bytes memory _json)
        internal
        pure
        returns (bytes32 domainSeparator_, bytes32 messageHash_)
    {
        string memory json = string(_json);
        require(bytes(json).length != 0, "GnosisSafeHashes: empty EIP-712 JSON");

        // Domain fields
        uint256 chainId = stdJson.readUint(json, ".domain.chainId");
        address verifyingContract = stdJson.readAddress(json, ".domain.verifyingContract");
        require(verifyingContract != address(0), "GnosisSafeHashes: verifyingContract is zero");
        // Compute domain separator according to the JSON schema used in encodeEIP712Json
        domainSeparator_ = keccak256(
            abi.encode(keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"), chainId, verifyingContract)
        );

        // Message fields
        address to = stdJson.readAddress(json, ".message.to");
        require(to != address(0), "GnosisSafeHashes: to is zero");
        uint256 value = stdJson.readUint(json, ".message.value");
        bytes memory data = stdJson.readBytes(json, ".message.data");
        uint8 operation = uint8(stdJson.readUint(json, ".message.operation"));
        require(operation == 1, "GnosisSafeHashes: invalid operation, only DelegateCall is supported");
        uint256 safeTxGas = stdJson.readUint(json, ".message.safeTxGas");
        uint256 baseGas = stdJson.readUint(json, ".message.baseGas");
        uint256 gasPrice = stdJson.readUint(json, ".message.gasPrice");
        address gasToken = stdJson.readAddress(json, ".message.gasToken");
        address refundReceiver = stdJson.readAddress(json, ".message.refundReceiver");
        uint256 nonce = stdJson.readUint(json, ".message.nonce");

        bytes32 dataHash = keccak256(data);
        messageHash_ = keccak256(
            abi.encode(
                SAFE_TX_TYPEHASH,
                to,
                value,
                dataHash,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                nonce
            )
        );
    }

    /// @notice Helper to decode multicall calldata and extract approveHash parameter.
    function decodeMulticallApproveHash(bytes memory _multicallCalldata) internal pure returns (bytes32) {
        uint256 selectorLength = 4;
        uint256 approveHashLength = 36; // 32 (length of hash) + 4 (selector) = 36
        require(_multicallCalldata.length >= selectorLength, "GnosisSafeHashes: calldata too short");

        // Create a new bytes array without the function selector
        bytes memory dataWithoutSelector = new bytes(_multicallCalldata.length - selectorLength);
        for (uint256 i = 0; i < dataWithoutSelector.length; i++) {
            dataWithoutSelector[i] = _multicallCalldata[i + selectorLength];
        }

        IMulticall3.Call3Value[] memory calls = abi.decode(dataWithoutSelector, (IMulticall3.Call3Value[]));
        require(calls.length == 1, "GnosisSafeHashes: expected single approval call");
        bytes memory approveCalldata = calls[0].callData;
        require(approveCalldata.length == approveHashLength, "GnosisSafeHashes: invalid approveHash calldata length");

        // Extract the hash parameter using assembly to skip the selector
        bytes32 hash;
        assembly {
            hash := mload(add(approveCalldata, approveHashLength))
        }
        return hash;
    }

    function getOperationDetails(VmSafe.AccountAccessKind _kind)
        internal
        pure
        returns (string memory opStr, Enum.Operation op)
    {
        if (_kind == VmSafe.AccountAccessKind.Call) {
            opStr = "Call";
            op = Enum.Operation.Call;
        } else if (_kind == VmSafe.AccountAccessKind.DelegateCall) {
            opStr = "DelegateCall";
            op = Enum.Operation.DelegateCall;
        } else {
            revert("Unknown account access kind");
        }
    }

    /// @notice Returns the bytes that are hashed before signing by EOA. This function is used by MultisigTask.
    function getEncodedTransactionData(
        address _safe,
        bytes memory _data,
        uint256 _value,
        uint256 _originalNonce,
        address _multicallAddress
    ) internal view returns (bytes memory encodedTxData) {
        encodedTxData = IGnosisSafe(_safe).encodeTransactionData({
            to: _multicallAddress,
            value: _value,
            data: _data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: _originalNonce
        });
        require(encodedTxData.length == 66, "GnosisSafeHashes: encodedTxData length is not 66 bytes.");
    }

    /// @notice Encodes the calldata for the Gnosis Safe execTransaction function.
    function encodeExecTransactionCalldata(
        address _safe,
        bytes memory _data,
        bytes memory _signatures,
        address _multicallTarget
    ) internal pure returns (bytes memory) {
        return abi.encodeCall(
            IGnosisSafe(_safe).execTransaction,
            (
                _multicallTarget,
                0,
                _data,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                _signatures
            )
        );
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

    /// @notice Encodes the EIP-712 JSON for a Safe transaction. Taken and modified from:
    /// https://github.com/base/contracts/pull/148/files#diff-72074ac05b528d57b61e77e3e0c6796a09cd56c4966a3d88a2c086b4a539ffce
    function encodeEIP712Json(address _multicallTarget, address _safe, SafeTransaction memory _safeTx)
        internal
        returns (bytes memory)
    {
        string memory types = '{"EIP712Domain":[' '{"name":"chainId","type":"uint256"},'
            '{"name":"verifyingContract","type":"address"}],' '"SafeTx":[' '{"name":"to","type":"address"},'
            '{"name":"value","type":"uint256"},' '{"name":"data","type":"bytes"},'
            '{"name":"operation","type":"uint8"},' '{"name":"safeTxGas","type":"uint256"},'
            '{"name":"baseGas","type":"uint256"},' '{"name":"gasPrice","type":"uint256"},'
            '{"name":"gasToken","type":"address"},' '{"name":"refundReceiver","type":"address"},'
            '{"name":"nonce","type":"uint256"}]}';

        string memory domain = stdJson.serialize("domain", "chainId", uint256(block.chainid));
        domain = stdJson.serialize("domain", "verifyingContract", address(_safe));

        string memory message = stdJson.serialize("message", "to", _multicallTarget);
        message = stdJson.serialize("message", "value", _safeTx.value);
        message = stdJson.serialize("message", "data", _safeTx.data);
        message = stdJson.serialize("message", "operation", uint256(_safeTx.operation));
        message = stdJson.serialize("message", "safeTxGas", uint256(_safeTx.safeTxGas));
        message = stdJson.serialize("message", "baseGas", uint256(_safeTx.baseGas));
        message = stdJson.serialize("message", "gasPrice", uint256(_safeTx.gasPrice));
        message = stdJson.serialize("message", "gasToken", address(_safeTx.gasToken));
        message = stdJson.serialize("message", "refundReceiver", address(_safeTx.refundReceiver));
        message = stdJson.serialize("message", "nonce", _safeTx.nonce);

        string memory json = stdJson.serialize("", "primaryType", string("SafeTx"));
        json = stdJson.serialize("", "types", types);
        json = stdJson.serialize("", "domain", domain);
        json = stdJson.serialize("", "message", message);

        return abi.encodePacked(json);
    }
}
