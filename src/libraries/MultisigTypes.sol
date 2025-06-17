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

/// @notice This struct contains all the data needed to execute a task.
/// All safes involved in the task must be represented in this struct.
struct TaskPayload {
    address[] safes;
    bytes[] calldatas;
    uint256[] originalNonces;
}

/// @notice Struct to store information about a safe
struct SafeData {
    address addr;
    bytes callData;
    uint256 nonce;
}
