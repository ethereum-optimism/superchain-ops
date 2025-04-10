// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

import {
    IDeputyPauseModule
} from "lib/optimism/packages/contracts-bedrock/interfaces/safe/IDeputyPauseModule.sol";

import {console} from "forge-std/console.sol";

/// @title DeputyPauseRotationKey
contract DeputyPauseRotationKey is L2TaskBase {
    using stdToml for string;
    /// @notice Struct to store inputs for deputyPauseModule.setDeputy() function L1. 
    
    // Store the inputs
    address new_deputy;
    bytes new_deputy_signature;
    
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
        // newModule = vm.parseTomlAddress(file, ".newModule");
        // assertNotEq(newModule.code.length, 0, "new module must have code");
        // Load the inputs from the task config
        new_deputy = vm.parseTomlAddress(file, ".newDeputy");
        new_deputy_signature = vm.parseTomlBytes(file, ".newDeputySignature");
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        // Load the DeputyPauseModule contract.
        IDeputyPauseModule dpm = IDeputyPauseModule(superchainAddrRegistry.get("DeputyPauseModule"));
        // 1. In the future, check that the DeputyPauseModule address is the one that is enabled in the foundation safe.
        // assertEq(fos.enabledmodule(address(dpm)), true, "ERR100: DeputyPauseModule is should be enabled");
        // 2. Check that the input are valid.     
        assertNotEq(dpm.deputy(), address(0), "ERR101: DeputyPauseModule should have already a deputy set in the past.");
        assertNotEq(dpm.deputy(), new_deputy, "ERR102: DeputyPauseModule should have a new deputy");
        
        // Check that the rotation signature is valid
        // The signature should be created by the new_deputy address over their own address
        // using EIP-712 typed data with the message format "DeputyAuthMessage(address deputy)"
        
        // Get the typehash for deputy auth messages
        // bytes32 deputyAuthMessageTypehash = dpm.deputyAuthMessageTypehash();
        
        // We can't directly call the internal _hashTypedDataV4 function from the contract
        // but we can validateggj§ the signature is right by checking if it reverts when passed to setDeputy
        // This serves as a pre-flight check before actual execution
        
        // Verify the new_deputy_signature is exactly 65 bytes (r, s, v format)
        require(new_deputy_signature.length == 65, "ERR104: Invalid signature length");
        // print the chainid 
        console.log("chainId", block.chainid);
        console.logBytes(new_deputy_signature);
        console.log("new_deputy_signature.length", new_deputy_signature.length);
        console.log("new_deputy", new_deputy);
        
        // 3. Rotate the new deputy and signature.
        dpm.setDeputy(new_deputy, new_deputy_signature);
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        IDeputyPauseModule dpm = IDeputyPauseModule(superchainAddrRegistry.get("DeputyPauseModule"));
        assertEq(dpm.deputy(), new_deputy, "ERR103: DeputyPauseModule should have a the new deputy set");
        // check the foundation has the DPM enabled. 
        // assertEq(fos.enabledmodule(address(dpm)), true, "ERR100: DeputyPauseModule is should be enabled");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view override returns (address[] memory) {
        address[] memory codeExceptions = new address[](1);
        codeExceptions[0] = new_deputy;

        return codeExceptions;
    }
}
