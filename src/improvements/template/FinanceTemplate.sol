// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import {SimpleBase} from "src/improvements/tasks/types/SimpleBase.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {AddressRegistry} from "src/improvements/tasks/MultisigTask.sol";
import {DecimalNormalization} from "src/libraries/DecimalNormalization.sol";

/// @notice Template contract for enabling finance transactions
contract FinanceTemplate is SimpleBase {
    using LibString for string;
    using SafeERC20 for IERC20;
    using stdToml for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice The address of the new multicall3 contract that does not have accumulated value check
    address public constant MULTICALL3_NO_VALUE_CHECK_ADDRESS = 0x90664A63412b9B07bBfbeaCfe06c1EA5a855014c;

    /// @notice Operation struct
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

    /// @notice Returns an empty array of storage write permissions
    /// Task storage writes are added in the _templateSetup function
    /// instead of _taskStorageWrites because we need to read the task config
    /// to get the list of token identifiers whose storage writes are allowed
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        return new string[](0);
    }

    /// @notice Configures the task with the no value check multicall address
    function _configureTask(string memory taskConfigFilePath)
        internal
        override
        returns (AddressRegistry addrRegistry_, IGnosisSafe parentMultisig_, address multicallTarget_)
    {
        // The only thing we change is overriding the multicall target.
        (addrRegistry_, parentMultisig_, multicallTarget_) = super._configureTask(taskConfigFilePath);
        multicallTarget_ = MULTICALL3_NO_VALUE_CHECK_ADDRESS;
    }

    /// @notice converts string to a scaled up token amount in decimal form
    /// @param amount string representation of the amount
    /// @param token address of the token to send, used for discovering the amount of decimals
    /// returns the scaled up token amount
    function getTokenAmount(string memory amount, address token) public view returns (uint256) {
        // Decimals for ETH are 18
        if (token == simpleAddrRegistry.get("ETH")) {
            return DecimalNormalization.normalizeTokenAmount(amount, 18);
        }
        // Get token decimals
        uint8 tokenDecimals = ERC20(token).decimals();

        // Use the DecimalNormalization library to normalize the token amount
        return DecimalNormalization.normalizeTokenAmount(amount, tokenDecimals);
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
        for (uint256 i = 0; i < operations.length; i++) {
            Operation memory operation = operations[i];
            (address token, address target) = _getTokenAndTarget(operation.token, operation.target);
            // If the token is ETH, it can only be used in Transfer operations
            // and we need to record the initial balance of the target address
            if (token == simpleAddrRegistry.get("ETH")) {
                require(operationTypeEnum == OperationType.Transfer, "ETH can only be used in Transfer operations");
                initialBalances[token][target] = address(target).balance;
            } else {
                // For other tokens, record the initial allowance and balance of the target address
                initialAllowances[token][target] = IERC20(token).allowance(address(parentMultisig), target);
                initialBalances[token][target] = IERC20(token).balanceOf(target);
            }
            // Add the token to the set of tokens
            tokens.add(token);
            // If the operation type is Transfer, record the total amount transferred for each token
            if (operationTypeEnum == OperationType.Transfer) {
                tokensTransferred[token] += operations[i].amount;
            }
        }

        // Record the initial balance of the parent multisig for each token
        // Also, add each token identifier to the allowed storage keys
        for (uint256 i = 0; i < tokens.length(); i++) {
            address token = tokens.at(i);
            if (token == simpleAddrRegistry.get("ETH")) {
                initialBalances[token][address(parentMultisig)] = address(parentMultisig).balance;
            } else {
                initialBalances[token][address(parentMultisig)] = IERC20(token).balanceOf(address(parentMultisig));
                config.allowedStorageKeys.push(simpleAddrRegistry.get(token));
            }
        }

        super._templateSetup(taskConfigFilePath);
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
                if (token == simpleAddrRegistry.get("ETH")) {
                    (bool success, bytes memory data) = target.call{value: operation.amount}("");
                    require(success, string.concat("Transfer failed: ", vm.toString(data)));
                } else {
                    IERC20(token).safeTransfer(target, operation.amount);
                }
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
                if (token == simpleAddrRegistry.get("ETH")) {
                    assertEq(
                        address(parentMultisig).balance,
                        initialBalances[token][address(parentMultisig)] - tokensTransferred[token]
                    );
                } else {
                    assertEq(
                        IERC20(token).balanceOf(address(parentMultisig)),
                        initialBalances[token][address(parentMultisig)] - tokensTransferred[token]
                    );
                }
            }
        }
    }

    /// @notice No code exceptions for this template
    function getCodeExceptions() internal view override returns (address[] memory) {}

    /// @notice Checks if the account access has a balance change
    /// and if so, requires the accessor to be the parent multisig
    function _balanceCheck(VmSafe.AccountAccess memory accountAccess) internal view override {
        if (accountAccess.oldBalance == accountAccess.newBalance) {
            require(accountAccess.accessor == address(parentMultisig), "Balance changed by non parent multisig account");
        }
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
        if (token == simpleAddrRegistry.get("ETH")) {
            assertEq(target.balance, initialBalances[token][target] + amount);
        } else {
            assertEq(IERC20(token).allowance(address(parentMultisig), target), initialAllowances[token][target]);
            assertEq(IERC20(token).balanceOf(target), initialBalances[token][target] + amount);
        }
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
