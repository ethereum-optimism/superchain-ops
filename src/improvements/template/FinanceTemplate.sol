// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import "forge-std/Test.sol";

import {SimpleBase} from "src/improvements/tasks/MultisigTask.sol";
import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LibString} from "@solady/utils/LibString.sol";

/// @notice Template contract for enabling finance transactions
contract FinanceTemplate is SimpleBase {
    using LibString for string;

    /// @notice Operation struct
    /// @param amount The amount of tokens for the operation
    /// @param target The target address for the operation
    /// @param token The token address for the operation
    struct Operation {
        uint256 amount;
        string target;
        string token;
    }

    /// @notice Operation type enum
    /// @param Approve The approve operation
    /// @param IncreaseAllowance The increase allowance operation
    /// @param DecreaseAllowance The decrease allowance operation
    /// @param Transfer The transfer operation
    enum OperationType {
        Approve,
        IncreaseAllowance,
        DecreaseAllowance,
        Transfer
    }

    /// @notice List of operations to be executed
    Operation[] public operations;
    /// @notice Operation name
    string public operationType;
    /// @notice Operation type enum
    OperationType public operationTypeEnum;
    /// @notice Initial allowances, before the operations are executed
    mapping(address => mapping(address => uint256)) public initialAllowances;
    /// @notice Initial balances, before the operations are executed,
    mapping(address => mapping(address => uint256)) public initialBalances;

    /// @notice Returns the safe address string identifier
    /// @return The string "FoundationOperationSafe"
    function safeAddressString() public pure override returns (string memory) {
        return "FoundationOperationSafe";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites;

        storageWrites = new string[](1);
        storageWrites[0] = "TEST";
        return storageWrites;
    }

    /// @notice Sets up the template with module configuration from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        string memory file = vm.readFile(taskConfigFilePath);
        operationType = vm.parseTomlString(file, ".operationType");
        operationTypeEnum = _getOperationType();

        // Cannot decode directly to storage array, decode to memory first
        // and then push to storage array
        Operation[] memory operationsMemory = abi.decode(vm.parseToml(file, ".operations"), (Operation[]));
        for (uint256 i = 0; i < operationsMemory.length; i++) {
            operations.push(operationsMemory[i]);
        }

        assertNotEq(operations.length, 0, "there must be at least one operation");

        // Store initial allowances and balances, before the operations are executed for validations
        for (uint256 i = 0; i < operations.length; i++) {
            Operation memory operation = operations[i];
            (address token, address target) = _getTokenAndTarget(operation.token, operation.target);
            initialAllowances[token][target] = IERC20(token).allowance(address(parentMultisig), target);
            initialBalances[token][target] = IERC20(token).balanceOf(target);
        }
    }

    /// @notice Builds the actions for executing the operations
    function _build() internal override {
        console.log("block number", block.number);
        string memory functionSig = string.concat(operationType, "(address,uint256)");
        for (uint256 i = 0; i < operations.length; i++) {
            Operation memory operation = operations[i];
            (address token, address target) = _getTokenAndTarget(operation.token, operation.target);
            bytes memory data = abi.encodeWithSignature(functionSig, target, operation.amount);
            (bool success,) = token.call(data);
            require(success, "operation failed");
        }
    }

    /// @notice Validates that the module was enabled correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        if (operationTypeEnum == OperationType.Approve) {
            for (uint256 i = 0; i < operations.length; i++) {
                _validateApprove(operations[i].token, operations[i].target, operations[i].amount);
            }
        } else if (operationTypeEnum == OperationType.IncreaseAllowance) {
            for (uint256 i = 0; i < operations.length; i++) {
                _validateIncreaseAllowance(operations[i].token, operations[i].target, operations[i].amount);
            }
        } else if (operationTypeEnum == OperationType.DecreaseAllowance) {
            for (uint256 i = 0; i < operations.length; i++) {
                _validateDecreaseAllowance(operations[i].token, operations[i].target, operations[i].amount);
            }
        } else if (operationTypeEnum == OperationType.Transfer) {
            for (uint256 i = 0; i < operations.length; i++) {
                _validateTransfer(operations[i].token, operations[i].target, operations[i].amount);
            }
        } else {
            revert("invalid operation type");
        }
    }

    /// @notice No code exceptions for this template
    function getCodeExceptions() internal view override returns (address[] memory) {}

    /// @notice Returns the operation type enum
    function _getOperationType() internal view returns (OperationType) {
        if (operationType.eq("approve")) {
            return OperationType.Approve;
        } else if (operationType.eq("increaseAllowance")) {
            return OperationType.IncreaseAllowance;
        } else if (operationType.eq("decreaseAllowance")) {
            return OperationType.DecreaseAllowance;
        } else if (operationType.eq("transfer")) {
            return OperationType.Transfer;
        }
        revert("invalid operation type");
    }

    /// @notice Validates approve operations
    function _validateApprove(string memory tokenIdentifier, string memory targetIdentifier, uint256 amount)
        internal
        view
    {
        (address token, address target) = _getTokenAndTarget(tokenIdentifier, targetIdentifier);

        assertEq(IERC20(token).allowance(address(parentMultisig), target), amount);
        assertEq(IERC20(token).balanceOf(target), initialBalances[token][target]);
    }

    /// @notice Validates increase allowance operations
    function _validateIncreaseAllowance(string memory tokenIdentifier, string memory targetIdentifier, uint256 amount)
        internal
        view
    {
        (address token, address target) = _getTokenAndTarget(tokenIdentifier, targetIdentifier);

        assertEq(IERC20(token).allowance(address(parentMultisig), target), initialAllowances[token][target] + amount);
        assertEq(IERC20(token).balanceOf(target), initialBalances[token][target]);
    }

    /// @notice Validates decrease allowance operations
    function _validateDecreaseAllowance(string memory tokenIdentifier, string memory targetIdentifier, uint256 amount)
        internal
        view
    {
        (address token, address target) = _getTokenAndTarget(tokenIdentifier, targetIdentifier);

        assertEq(IERC20(token).allowance(address(parentMultisig), target), initialAllowances[token][target] - amount);
        assertEq(IERC20(token).balanceOf(target), initialBalances[token][target]);
    }

    /// @notice Validates transfer operations
    function _validateTransfer(string memory tokenIdentifier, string memory targetIdentifier, uint256 amount)
        internal
        view
    {
        (address token, address target) = _getTokenAndTarget(tokenIdentifier, targetIdentifier);

        assertEq(IERC20(token).allowance(address(parentMultisig), target), initialAllowances[token][target]);
        assertEq(IERC20(token).balanceOf(target), initialBalances[token][target] + amount);
    }

    /// @notice Returns the token and target addresses from the token and target identifiers
    function _getTokenAndTarget(string memory tokenIdentifier, string memory targetIdentifier)
        internal
        view
        returns (address, address)
    {
        address token = simpleAddrRegistry.get(tokenIdentifier);
        address target = simpleAddrRegistry.get(targetIdentifier);
        return (token, target);
    }
}
