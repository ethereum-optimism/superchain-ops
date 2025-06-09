// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IDeputyPauseModule} from "lib/optimism/packages/contracts-bedrock/interfaces/safe/IDeputyPauseModule.sol";

import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title DeputyPauseRotationKey
contract DeputyPauseKeyRotationTemplate is SimpleTaskBase {
    using stdToml for string;

    // Store the inputs
    address newDeputy;
    bytes newDeputySignature;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "FoundationOperationsSafe";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "DeputyPauseModule";
        storageWrites[1] = safeAddressString();
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);

        string memory file = vm.readFile(taskConfigFilePath);

        // Load the inputs from the task config
        newDeputy = vm.parseTomlAddress(file, ".newDeputy");
        newDeputySignature = vm.parseTomlBytes(file, ".newDeputySignature");
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        // Load the DeputyPauseModule contract.
        IDeputyPauseModule dpm = IDeputyPauseModule(simpleAddrRegistry.get("DeputyPauseModule"));
        // 1. In the future task we need to check that the DeputyPauseModule address is the one that is enabled in the foundation safe since in U13 task we will execute this task before activation this is different.
        // assertEq(fos.enabledmodule(address(dpm)), true, "ERR100: DeputyPauseModule is should be enabled");

        // 2. Check that the input are valid.
        assertNotEq(dpm.deputy(), address(0), "ERR101: DeputyPauseModule should have already a deputy set in the past.");
        assertNotEq(dpm.deputy(), newDeputy, "ERR102: DeputyPauseModule should have a new deputy");

        // Check that the rotation signature is valid
        // The signature should be created by the new_deputy address over their own address
        // using EIP-712 typed data with the message format "DeputyAuthMessage(address deputy)"
        require(newDeputySignature.length == 65, "ERR104: Invalid signature length");

        // 3. Rotate the new deputy and signature.
        dpm.setDeputy(newDeputy, newDeputySignature);
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        IDeputyPauseModule dpm = IDeputyPauseModule(simpleAddrRegistry.get("DeputyPauseModule"));
        assertEq(dpm.deputy(), newDeputy, "ERR103: DeputyPauseModule should have a the new deputy set");
        // check the foundation has the DPM enabled.
        // assertEq(fos.enabledmodule(address(dpm)), true, "ERR100: DeputyPauseModule is should be enabled");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view override returns (address[] memory) {
        address[] memory codeExceptions = new address[](1);
        codeExceptions[0] = newDeputy;

        return codeExceptions;
    }
}
