// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigTask, AddressRegistry} from "src/improvements/tasks/MultisigTask.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

abstract contract SimpleBase is MultisigTask {
    using EnumerableSet for EnumerableSet.AddressSet;

    SimpleAddressRegistry public simpleAddrRegistry;

    /// @notice Returns the type of task. SimpleBase.
    /// Overrides the taskType function in the MultisigTask contract.
    function taskType() public pure override returns (TaskType) {
        return TaskType.SimpleBase;
    }

    /// @notice Configures the task for SimpleBase type tasks.
    /// Overrides the configureTask function in the MultisigTask contract.
    /// For SimpleBase, we need to configure the simple address registry.
    function _configureTask(string memory taskConfigFilePath)
        internal
        virtual
        override
        returns (AddressRegistry addrRegistry_, IGnosisSafe parentMultisig_, address multicallTarget_)
    {
        multicallTarget_ = MULTICALL3_NO_VALUE_CHECK_ADDRESS;

        simpleAddrRegistry = new SimpleAddressRegistry(taskConfigFilePath);
        addrRegistry_ = AddressRegistry.wrap(address(simpleAddrRegistry));

        parentMultisig_ = IGnosisSafe(simpleAddrRegistry.get(config.safeAddressString));
    }

    /// @notice We use this function to add allowed storage accesses.
    function _templateSetup(string memory) internal virtual override {
        for (uint256 i = 0; i < config.allowedStorageKeys.length; i++) {
            _allowedStorageAccesses.add(simpleAddrRegistry.get(config.allowedStorageKeys[i]));
        }
    }
}
