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
