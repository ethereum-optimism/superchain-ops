// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

/// @notice Interface of the UnorderedExecutionModule, the Safe module that executes transactions
/// authorized by owner signatures over the Safe's transaction hash computed with a "hash-once"
/// value in the nonce slot instead of the sequential nonce.
/// Source: optimism monorepo, packages/contracts-bedrock/src/safe/UnorderedExecutionModule.sol
interface IUnorderedExecutionModule {
    /// @notice Parameters for the Safe transaction being executed. The remaining fields of the
    /// signed Safe transaction (safeTxGas, baseGas, gasPrice, gasToken, refundReceiver) are
    /// hard-coded to zero and the nonce is supplied separately as the hash-once value.
    struct ExecTransactionParams {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
    }

    /// @notice Derives the canonical hash-once value from a unique string.
    function deriveHashOnce(string memory _input) external pure returns (uint256 hashOnce_);

    /// @notice Whether a hash-once value has been consumed by an execution on the given Safe.
    function executed(address _safe, uint256 _hashOnce) external view returns (bool executed_);

    /// @notice The Safe transaction hash owners must sign: the Safe's own getTransactionHash()
    /// with the hash-once value in the nonce slot and zeroed gas and refund fields.
    function transactionHash(address _safe, ExecTransactionParams memory _params, uint256 _hashOnce)
        external
        view
        returns (bytes32 txHash_);

    /// @notice Executes a transaction once a threshold of owner signatures has been collected.
    /// Reverts if the call reverts, leaving the hash-once value unconsumed.
    function execute(
        address _safe,
        ExecTransactionParams calldata _params,
        uint256 _hashOnce,
        bytes calldata _signatures
    ) external returns (bytes memory returnData_);
}
