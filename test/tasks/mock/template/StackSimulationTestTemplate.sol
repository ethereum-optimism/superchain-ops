// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A simple contract that's used to test stacked simulations.
/// It's setup in such a way that later tasks in the stack depend on the state changes
/// from previous tasks in the stack.
contract SimpleStorage {
    /// @notice This is the first value that is set. We include this variable to make sure this state persists across multiple simulations.
    uint256 public first = type(uint256).max;
    /// @notice This is the current value of the storage slot.
    uint256 public current;

    /// @notice Function that allows us to check if state is persistent across multiple simulations.
    function set(uint256 firstValue, uint256 oldValue, uint256 newValue) public {
        require(oldValue == current, "SimpleStorage: oldValue != current");
        current = newValue;

        if (first == type(uint256).max) {
            first = firstValue; // Only set the first value once.
        } else {
            require(first == firstValue, "SimpleStorage: firstValue != first");
        }
    }
}

/// @notice Template contract that's used to test stacked simulations.
contract StackSimulationTestTemplate is SimpleTaskBase {
    using stdToml for string;

    uint256 public oldValue;
    uint256 public newValue;
    uint256 public firstValue;

    function safeAddressString() public pure override returns (string memory) {
        return "SimpleStorageOwner";
    }

    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "SimpleStorageOwner";
        storageWrites[1] = "SimpleStorage";
        return storageWrites;
    }

    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory toml = vm.readFile(taskConfigFilePath);
        oldValue = toml.readUint(".oldValue");
        newValue = toml.readUint(".newValue");
        firstValue = toml.readUint(".firstValue");
    }

    function _build() internal override {
        SimpleStorage simpleStorage = SimpleStorage(simpleAddrRegistry.get("SimpleStorage"));
        simpleStorage.set(firstValue, oldValue, newValue);
    }

    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SimpleStorage simpleStorage = SimpleStorage(simpleAddrRegistry.get("SimpleStorage"));
        assertEq(simpleStorage.current(), newValue);
        assertEq(simpleStorage.first(), firstValue);
    }

    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
