// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import "forge-std/Test.sol";

import {SimpleBase} from "src/improvements/tasks/MultisigTask.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

/// @notice Template contract for enabling finance transactions
contract FinanceTemplate is SimpleBase {
    using LibString for string;
    using SafeERC20 for IERC20;
    using stdToml for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Operation struct as read in from the `config.toml` file
    /// @param amount The amount of tokens for the operation, specified
    /// as a decimal. i.e. `100.1`
    /// @param target The target address for the operation
    /// @param token The token address for the operation
    struct FileOperation {
        string amount;
        string target;
        string token;
    }

    /// @notice Operation struct that is persisted to storage
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

    /// @notice Set of tokens that have been used in the operations
    EnumerableSet.AddressSet internal tokens;

    /// @notice Mapping of tokens to the amounts transferred
    /// in case the operation type is Transfer
    mapping(address => uint256) public tokensTransferred;

    /// @notice The safe to send this transaction from must be specified in the config file.
    function safeAddressString() public pure override returns (string memory) {
        return "SafeToSendFrom";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        return new string[](0);
    }

    /// @notice add the decimals to the given amount
    /// @param amount The amount to scale
    /// @param decimals The number of decimals to scale by
    function scaleDecimals(uint256 amount, uint8 decimals) public pure returns (uint256) {
        return amount * (10 ** uint256(decimals));
    }

    /// @notice returns the amount with the length of the decimals parsed
    /// @param amount The amount to parse
    /// @return The amount and the number of decimals
    function parseDecimals(string memory amount) public pure returns (uint256, uint8) {
        string[] memory components = amount.split(".");
        uint256 decimals;
        if (components.length == 2) {
            decimals = bytes(components[1]).length;
            require(decimals != 0, "decimals cannot be 0");
        }

        /// handle the no decimal cases:
        ///   amount is "100", or amount is "100.0" "100.00", etc
        if (components.length == 1 || vm.parseUint(components[1]) == 0) {
            // no decimals
            return (vm.parseUint(components[0]), 0);
        } else if (components.length == 2) {
            // handle the decimals case
            require(decimals <= 18, "decimals must be less than or equal to 18");
            uint256 tokenAmount = vm.parseUint(components[0]);
            require(tokenAmount != 0, "token amount must be non zero");

            return (
                scaleDecimals(tokenAmount, uint8(decimals)) + vm.parseUint(components[1]),
                uint8(decimals)
            );
        }

        revert("invalid amount");
    }

    /// @notice converts string to a scaled up token amount in decimal form
    /// @param amount string representation of the amount
    /// @param token address of the token to send, used discovering the decimals
    /// returns the scaled up token amount
    function getTokenAmount(string memory amount, address token) public view returns (uint256) {
        (uint256 scaledAmount, uint8 amountDecimals) = parseDecimals(amount);
        uint8 decimals = ERC20(token).decimals();

        require(amountDecimals <= decimals, "amount decimals must be less than or equal to token decimals");

        return scaleDecimals(scaledAmount, decimals - amountDecimals);
    }

    /// @notice Sets up the template with module configuration from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        string memory toml = vm.readFile(taskConfigFilePath);
        operationType = toml.readString(".operationType");
        operationTypeEnum = _getOperationType();

        // Cannot decode directly to storage array, decode to memory first
        // and then push to storage array
        FileOperation[] memory operationsMemory = abi.decode(toml.parseRaw(".operations"), (FileOperation[]));
        for (uint256 i = 0; i < operationsMemory.length; i++) {
            Operation memory taskOperation = Operation({
                amount: getTokenAmount(operationsMemory[i].amount, simpleAddrRegistry.get(operationsMemory[i].token)),
                target: operationsMemory[i].target,
                token: operationsMemory[i].token
            });

            operations.push(taskOperation);
        }

        assertNotEq(operations.length, 0, "there must be at least one operation");

        // Store initial allowances and balances, before the operations are executed for validations
        // also add the token to the set of tokens
        for (uint256 i = 0; i < operations.length; i++) {
            Operation memory operation = operations[i];
            (address token, address target) = _getTokenAndTarget(operation.token, operation.target);
            tokens.add(token);
            initialAllowances[token][target] = IERC20(token).allowance(address(parentMultisig), target);
            initialBalances[token][target] = IERC20(token).balanceOf(target);
            if (operationTypeEnum == OperationType.Transfer) {
                tokensTransferred[token] += operations[i].amount;
            }
        }

        for (uint256 i = 0; i < tokens.length(); i++) {
            address token = tokens.at(i);
            initialBalances[token][address(parentMultisig)] = IERC20(token).balanceOf(address(parentMultisig));
        }
    }

    /// @notice Builds the actions for executing the operations
    function _build() internal override {
        for (uint256 i = 0; i < operations.length; i++) {
            Operation memory operation = operations[i];
            (address token, address target) = _getTokenAndTarget(operation.token, operation.target);

            if (operationTypeEnum == OperationType.Approve) {
                IERC20(token).safeApprove(target, operation.amount);
            } else if (operationTypeEnum == OperationType.IncreaseAllowance) {
                IERC20(token).safeIncreaseAllowance(target, operation.amount);
            } else if (operationTypeEnum == OperationType.DecreaseAllowance) {
                IERC20(token).safeDecreaseAllowance(target, operation.amount);
            } else if (operationTypeEnum == OperationType.Transfer) {
                IERC20(token).safeTransfer(target, operation.amount);
            } else {
                revert("invalid operation type");
            }
        }
    }

    /// @notice Validates that the module was enabled correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        for (uint256 i = 0; i < operations.length; i++) {
            Operation memory operation = operations[i];
            (address token, address target) = _getTokenAndTarget(operation.token, operation.target);

            if (operationTypeEnum == OperationType.Approve) {
                _validateApprove(token, target, operation.amount);
            } else if (operationTypeEnum == OperationType.IncreaseAllowance) {
                _validateIncreaseAllowance(token, target, operation.amount);
            } else if (operationTypeEnum == OperationType.DecreaseAllowance) {
                _validateDecreaseAllowance(token, target, operation.amount);
            } else if (operationTypeEnum == OperationType.Transfer) {
                _validateTransfer(token, target, operation.amount);
            } else {
                revert("invalid operation type");
            }
        }

        if (operationTypeEnum == OperationType.Transfer) {
            // validate that parentMultisig balance decreased by the correct amount of tokens transferred
            for (uint256 i = 0; i < tokens.length(); i++) {
                address token = tokens.at(i);
                assertEq(
                    IERC20(token).balanceOf(address(parentMultisig)),
                    initialBalances[token][address(parentMultisig)] - tokensTransferred[token]
                );
            }
        }
    }

    /// @notice No code exceptions for this template
    function getCodeExceptions() internal view override returns (address[] memory) {}

    /// @notice No storage write checks for this template
    /// TODO: Remove this function once we can set token storage writes in the FinanceTemplate
    function _checkStorageWrites() internal pure override returns (bool) {
        return false;
    }

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
    function _validateApprove(address token, address target, uint256 amount) internal view {
        assertEq(IERC20(token).allowance(address(parentMultisig), target), amount);
        assertEq(IERC20(token).balanceOf(target), initialBalances[token][target]);
    }

    /// @notice Validates increase allowance operations
    function _validateIncreaseAllowance(address token, address target, uint256 amount) internal view {
        assertEq(IERC20(token).allowance(address(parentMultisig), target), initialAllowances[token][target] + amount);
        assertEq(IERC20(token).balanceOf(target), initialBalances[token][target]);
    }

    /// @notice Validates decrease allowance operations
    function _validateDecreaseAllowance(address token, address target, uint256 amount) internal view {
        assertEq(IERC20(token).allowance(address(parentMultisig), target), initialAllowances[token][target] - amount);
        assertEq(IERC20(token).balanceOf(target), initialBalances[token][target]);
    }

    /// @notice Validates transfer operations
    function _validateTransfer(address token, address target, uint256 amount) internal view {
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
