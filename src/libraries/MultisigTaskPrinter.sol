// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdStyle} from "forge-std/StdStyle.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Utils} from "src/libraries/Utils.sol";

/// @notice A library for handling all console output related to MultisigTask operations.
/// This library centralizes UI formatting, transaction data printing, and status message logging
/// to reduce code duplication and maintain consistent output formats. It also allows
/// `MultisigTask.sol` to focus simply on business logic, and not be concerned with formatting.
library MultisigTaskPrinter {
    using StdStyle for string;

    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // ==========================================
    // =========== Core UI Elements ============
    // ==========================================

    /// @notice Prints a formatted title with decorative elements.
    function printTitle(string memory title) internal pure {
        console.log("");
        console.log(vm.toUppercase(title).cyan().bold());
        string memory line = unicode"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        console.log(line.cyan().bold());
    }

    /// @notice Prints the welcome message and conditionally the developer attention preamble.
    function printWelcomeMessage() internal view {
        console.log("");
        string memory line = unicode"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        console.log(line.cyan().bold());
        console.log("                 WELCOME TO SUPERCHAIN-OPS");
        console.log(line.cyan().bold());
        if (!Utils.isFeatureEnabled("SIGNING_MODE_IN_PROGRESS")) {
            printDeveloperAttentionPreamble();
        }
    }

    /// @notice Prints the developer attention preamble with instructions.
    function printDeveloperAttentionPreamble() internal pure {
        printTitle("ATTENTION TASK DEVELOPERS");
        console.log("To properly document the task state changes, please follow these steps:");
        console.log("1. Copy and paste the state changes printed below into the VALIDATION.md file.");
        console.log(
            "2. For each task, write a thorough 'Detail' and 'Summary' section explaining the state change, providing links where appropriate."
        );
        console.log("3. Ensure the state changes are expected and match those seen in the Tenderly simulation.");
    }

    // ==========================================
    // =========== Transaction Data ============
    // ==========================================

    /// @notice Prints raw task calldata bytes within a formatted title section.
    function printTaskCalldata(bytes memory taskCalldata) internal pure {
        printTitle("TASK CALLDATA");
        console.logBytes(taskCalldata);
    }

    /// @notice Prints all information related to nested multisig transactions
    /// @param parentMultisigLabel The label of the parent multisig
    /// @param childMultisigLabel The label of the child multisig
    /// @param parentHashToApprove The hash that the child multisig needs to approve
    /// @param dataToSign The encoded transaction data for the child to sign
    /// @param domainSeparator The domain separator for the child multisig
    /// @param messageHash The message hash for the child multisig
    function printNestedDataInfo(
        string memory parentMultisigLabel,
        string memory childMultisigLabel,
        bytes32 parentHashToApprove,
        bytes memory dataToSign,
        bytes32 domainSeparator,
        bytes32 messageHash
    ) internal view {
        console.log("");
        printTitle("NESTED MULTISIG CHILD'S HASH TO APPROVE");
        console.log("Parent multisig: %s", parentMultisigLabel);
        console.log("Parent hashToApprove: %s", vm.toString(parentHashToApprove));
        printEncodedTransactionData(dataToSign);

        console.log("");
        printTitle("NESTED MULTISIG EOAS HASH TO APPROVE");
        printChildSafeHashInfo(childMultisigLabel, domainSeparator, messageHash);
    }

    /// @notice Prints encoded transaction data with formatted header and footer and instructions for signers.
    /// @param dataToSign The encoded transaction data to sign.
    function printEncodedTransactionData(bytes memory dataToSign) internal view {
        // NOTE: Do not change the vvvvvvvv and ^^^^^^^^ lines, as the eip712sign tool explicitly
        // looks for those specific lines to identify the data to sign.
        printTitle("DATA TO SIGN");
        // 'SUPPRESS_PRINTING_DATA_TO_SIGN' is true only when using stacked signing and the task is not the last task in the stack.
        bool shouldPrintDataToSign = !Utils.isFeatureEnabled("SUPPRESS_PRINTING_DATA_TO_SIGN");
        if (shouldPrintDataToSign) {
            console.log("vvvvvvvv");
            console.logBytes(dataToSign);
            console.log("^^^^^^^^\n");

            printTitle("ATTENTION SIGNERS");
            console.log("Please verify that the 'Data to sign' displayed above matches:");
            console.log("1. The data shown in the Tenderly simulation.");
            console.log("2. The data shown on your hardware wallet.");
            console.log("This is a critical step. Do not skip this verification.");
        } else {
            console.log("This task is not intended to be signed. Not printing data to sign.");
        }
    }

    /// @notice Prints the Tenderly simulation payload with the state overrides.
    function printTenderlySimulationData(
        address targetAddress,
        bytes memory finalExec,
        address sender,
        Simulation.StateOverride[] memory overrides
    ) internal view {
        printTitle("TENDERLY SIMULATION DATA");
        console.log("\nSimulation link:");
        Simulation.logSimulationLink({_to: targetAddress, _data: finalExec, _from: sender, _overrides: overrides});
    }

    // ==========================================
    // ======= Verification Information ========
    // ==========================================

    /// @notice Prints the hash information for a child safe transaction.
    function printChildSafeHashInfo(string memory childMultisigLabel, bytes32 domainSeparator, bytes32 messageHash)
        internal
        pure
    {
        bytes32 safeTxHash = keccak256(abi.encodePacked(hex"1901", domainSeparator, messageHash));
        console.log("Child multisig: %s", childMultisigLabel);
        console.log("Safe Transaction Hash: ", vm.toString(safeTxHash));
        console.log("Domain Hash:           ", vm.toString(domainSeparator));
        console.log("Message Hash:          ", vm.toString(messageHash));
    }

    /// @notice Prints audit report information with normalized state diff hash.
    function printAuditReportInfo(bytes32 normalizedStateDiffHash) internal pure {
        printTitle("AUDIT REPORT INFORMATION");
        // forgefmt: disable-start
        console.log("The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.");
        console.log("As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.");
        console.log("");
        console.log("Normalized hash: %s", vm.toString(normalizedStateDiffHash));
        console.log("");
        // forgefmt: disable-end
    }

    /// @notice Prints an OP-TxVerify link for transaction verification.
    /// @param parentMultisig The address of the parent multisig.
    /// @param chainId The chain ID.
    /// @param childMultisig The address of the child multisig (can be address(0) if not nested).
    /// @param parentCalldata The calldata for the parent multisig.
    /// @param optionalChildCallData The calldata for the child multisig (can be empty if not nested)
    /// @param parentNonce The nonce of the parent multisig
    /// @param childNonce The nonce of the child multisig (can be 0 if not nested)
    /// @param parentMulticallTarget The target address for the parent multicall
    /// @param childMulticallTarget The target address for the child multicall (can be address(0) if not nested and matches parentMulticallTarget behavior
    function printOPTxVerifyLink(
        address parentMultisig,
        uint256 chainId,
        address childMultisig, // Can be address(0) if not nested
        bytes memory parentCalldata,
        bytes memory optionalChildCallData, // Can be empty if not nested
        uint256 parentNonce,
        uint256 childNonce, // Can be 0 if not nested
        address parentMulticallTarget,
        address childMulticallTarget // Can be address(0) if not nested and matches parentMulticallTarget behavior
    ) internal view {
        bool isNested = childMultisig != address(0);
        string memory json = string.concat(
            '{\n   "safe": "',
            vm.toString(parentMultisig),
            '",\n    "safe_version": "',
            IGnosisSafe(parentMultisig).VERSION(),
            '",\n   "chain": ',
            vm.toString(chainId),
            ',\n   "to": "',
            vm.toString(parentMulticallTarget),
            '",\n   "value": ',
            vm.toString(uint256(0)),
            ',\n   "data": "',
            vm.toString(parentCalldata)
        );

        json = string.concat(
            json,
            '",\n   "operation": ',
            vm.toString(uint8(Enum.Operation.DelegateCall)),
            ',\n   "safe_tx_gas": ',
            vm.toString(uint256(0)),
            ',\n   "base_gas": ',
            vm.toString(uint256(0)),
            ',\n   "gas_price": ',
            vm.toString(uint256(0)),
            ',\n   "gas_token": "',
            vm.toString(address(0)),
            '",\n   "refund_receiver": "',
            vm.toString(address(0))
        );

        json = string.concat(
            json,
            '",\n   "nonce": ',
            vm.toString(parentNonce),
            isNested
                ? string.concat(
                    ',\n   "nested": ',
                    '{\n    "safe": "',
                    vm.toString(childMultisig),
                    '",\n    "safe_version": "',
                    IGnosisSafe(childMultisig).VERSION(),
                    '",\n    "nonce": ',
                    vm.toString(childNonce),
                    ',\n    "operation": ',
                    vm.toString(uint8(Enum.Operation.DelegateCall)),
                    ',\n    "data": "',
                    vm.toString(optionalChildCallData),
                    '",\n    "to": "',
                    vm.toString(childMulticallTarget),
                    '"\n   }'
                )
                : "",
            "\n}"
        );

        string memory base64Json = Base64.encode(bytes(json));
        printTitle("OP-TXVERIFY LINK");
        console.log(
            "To verify this transaction, run `op-txverify qr` on your machine, then open the following link on your mobile device: https://op-txverify.optimism.io/?tx=%s",
            base64Json
        );
    }

    // ===================================================
    // ============ Status Messages / Helpers ============
    // ===================================================

    /// @notice Prints gas information for execTransaction if not in signing mode
    /// @param gas The amount of gas to use
    function printGasForExecTransaction(uint256 gas) internal view {
        // This function is view because Utils.isFeatureEnabled is view
        if (!Utils.isFeatureEnabled("SIGNING_MODE_IN_PROGRESS")) {
            console.log("Passing %s gas to execTransaction (from env or gasleft)", gas);
        }
    }

    /// @notice Prints an error message when executing a multisig transaction fails
    /// @param returnData The return data from the failed transaction
    function printErrorExecutingMultisigTransaction(bytes memory returnData) internal pure {
        console.log("Error executing multisig transaction");
        console.logBytes(returnData);
    }

    /// @notice Helper method to get labels for addresses.
    function getAddressLabel(address contractAddress) internal view returns (string memory) {
        string memory label = vm.getLabel(contractAddress);

        bytes memory prefix = bytes("unlabeled:");
        bytes memory strBytes = bytes(label);

        if (strBytes.length >= prefix.length) {
            // check if address is unlabeled
            for (uint256 i = 0; i < prefix.length; i++) {
                if (strBytes[i] != prefix[i]) {
                    // return "{LABEL} @{ADDRESS}" if address is labeled
                    return string(abi.encodePacked(label, " @", vm.toString(contractAddress)));
                }
            }
        } else {
            // return "{LABEL} @{ADDRESS}" if address is labeled
            return string(abi.encodePacked(label, " @", vm.toString(contractAddress)));
        }

        // return "UNLABELED @{ADDRESS}" if address is unlabeled
        return string(abi.encodePacked("UNLABELED @", vm.toString(contractAddress)));
    }
}
