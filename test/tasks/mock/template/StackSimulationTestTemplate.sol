// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {stdToml} from "forge-std/StdToml.sol";

contract SimpleStorage {
    uint256 public x;

    function set(uint256 oldValue, uint256 newValue) public {
        require(oldValue == x, "SimpleStorage: oldValue != x");
        x = newValue;
    }
}

/// @notice Template contract that's used to test stacked simulations.
contract StackSimulationTestTemplate is SimpleTaskBase {
    using stdToml for string;

    uint256 public oldValue;
    uint256 public newValue;

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
    }

    function _build() internal override {
        SimpleStorage simpleStorage = SimpleStorage(simpleAddrRegistry.get("SimpleStorage"));
        simpleStorage.set(oldValue, newValue);
    }

    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SimpleStorage simpleStorage = SimpleStorage(simpleAddrRegistry.get("SimpleStorage"));
        assertEq(simpleStorage.x(), newValue);
    }

    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
