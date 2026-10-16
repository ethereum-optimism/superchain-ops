// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IUnorderedExecutionModule} from "src/interfaces/IUnorderedExecutionModule.sol";

/// @notice Test-only port of the monorepo's UnorderedExecutionModule
/// (packages/contracts-bedrock/src/safe/UnorderedExecutionModule.sol, pragma 0.8.25), compiled at
/// this repo's pinned 0.8.15 against IGnosisSafe. Behavior must match the real module: same
/// transaction hash scheme (hash-once value in the nonce slot, zeroed gas and refund fields),
/// same (safe, hashOnce) replay protection, same signature verification via checkSignatures.
/// Implementing IUnorderedExecutionModule makes interface drift a compile error.
contract MockUnorderedExecutionModule is IUnorderedExecutionModule {
    error UnorderedExecutionModule_ModuleNotEnabled();
    error UnorderedExecutionModule_HashOnceTooSmall();
    error UnorderedExecutionModule_HashOnceAlreadyUsed();
    error UnorderedExecutionModule_UnsupportedSafe();
    error UnorderedExecutionModule_ExecutionFailed(bytes);

    event TransactionExecuted(address indexed safe, bytes32 indexed txHash, uint256 indexed hashOnce);

    mapping(address => mapping(uint256 => bool)) internal _executed;

    function executed(address _safe, uint256 _hashOnce) public view returns (bool executed_) {
        executed_ = _executed[_safe][_hashOnce];
    }

    function deriveHashOnce(string memory _input) public pure returns (uint256 hashOnce_) {
        hashOnce_ = uint256(keccak256(bytes(_input)));
    }

    function transactionHash(address _safe, ExecTransactionParams memory _params, uint256 _hashOnce)
        public
        view
        returns (bytes32 txHash_)
    {
        txHash_ = IGnosisSafe(_safe).getTransactionHash(
            _params.to, _params.value, _params.data, _params.operation, 0, 0, 0, address(0), address(0), _hashOnce
        );
    }

    function execute(
        address _safe,
        ExecTransactionParams calldata _params,
        uint256 _hashOnce,
        bytes calldata _signatures
    ) external returns (bytes memory returnData_) {
        if (!IGnosisSafe(_safe).isModuleEnabled(address(this))) {
            revert UnorderedExecutionModule_ModuleNotEnabled();
        }

        if (_hashOnce <= type(uint128).max) {
            revert UnorderedExecutionModule_HashOnceTooSmall();
        }

        if (_executed[_safe][_hashOnce]) {
            revert UnorderedExecutionModule_HashOnceAlreadyUsed();
        }

        bytes32 txHash = transactionHash(_safe, _params, _hashOnce);
        bytes memory txHashData = _encodeTransactionData(_safe, _params, _hashOnce);

        if (keccak256(txHashData) != txHash) {
            revert UnorderedExecutionModule_UnsupportedSafe();
        }

        IGnosisSafe(_safe).checkSignatures(txHash, txHashData, _signatures);

        _executed[_safe][_hashOnce] = true;

        bool success;
        (success, returnData_) = IGnosisSafe(_safe).execTransactionFromModuleReturnData(
            _params.to, _params.value, _params.data, _params.operation
        );

        if (!success) {
            revert UnorderedExecutionModule_ExecutionFailed(returnData_);
        }

        emit TransactionExecuted(_safe, txHash, _hashOnce);
    }

    function _encodeTransactionData(address _safe, ExecTransactionParams memory _params, uint256 _hashOnce)
        internal
        view
        returns (bytes memory txHashData_)
    {
        txHashData_ = IGnosisSafe(_safe).encodeTransactionData(
            _params.to, _params.value, _params.data, _params.operation, 0, 0, 0, address(0), address(0), _hashOnce
        );
    }
}
