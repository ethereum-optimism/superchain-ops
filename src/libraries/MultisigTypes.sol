// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

/// @notice Payload for a single multisig action.
/// @param target The address of the target contract to call.
/// @param value The amount of ETH to send with the action.
/// @param arguments The calldata to call on the target contract.
/// @param callType The type of call to be made, either Call or DelegateCall.
/// @param description A description of the action.
struct Action {
    address target;
    uint256 value;
    bytes arguments;
    Enum.Operation operation;
    string description;
}

/// @notice This type is from the Multicall3 contract.
/// @param target The address of the target contract to call.
/// @param allowFailure When true, the call is allowed to fail without reverting the entire transaction.
/// @param value The amount of ETH to send with the call.
/// @param callData The calldata to call on the target contract.
struct Call3Value {
    address target;
    bool allowFailure;
    uint256 value;
    bytes callData;
}

/// @notice Struct to store information about a token/Eth transfer
/// @param to The address of the recipient
/// @param value The amount of tokens/Eth to transfer
/// @param tokenAddress The address of the token contract
struct TransferInfo {
    address to;
    uint256 value;
    address tokenAddress;
}

/// @notice Struct to store information about a state change
/// @param slot The storage slot that is being updated
/// @param oldValue The old value of the storage slot
/// @param newValue The new value of the storage slot
struct StateInfo {
    bytes32 slot;
    bytes32 oldValue;
    bytes32 newValue;
}

/// @notice Enum to determine the type of task
enum TaskType {
    L2TaskBase,
    SimpleTaskBase,
    OPCMTaskBase
}

/// @notice Struct to store information about a L2 chain
struct L2Chain {
    uint256 chainId;
    string name;
}

/// @notice Config that is defined by the template of a given task.
struct TemplateConfig {
    string[] allowedStorageKeys;
    string[] allowedBalanceChanges;
    string safeAddressString;
}

/// @notice Detailed task configuration.
struct TaskConfig {
    L2Chain[] optionalL2Chains;
    string basePath;
    string configPath;
    string templateName;
    address parentMultisig;
    bool isNested;
    address task; // MultisigTask address
}
