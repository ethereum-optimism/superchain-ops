// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigTask, AddressRegistry} from "src/improvements/tasks/MultisigTask.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {TaskType} from "src/libraries/MultisigTypes.sol";

/// @notice This contract is used for all simple task types. It overrides various functions in the MultisigTask contract.
abstract contract SimpleTaskBase is MultisigTask {
    using EnumerableSet for EnumerableSet.AddressSet;

    SimpleAddressRegistry public simpleAddrRegistry;

    /// @notice Returns the type of task. SimpleTaskBase.
    /// Overrides the taskType function in the MultisigTask contract.
    function taskType() public pure override returns (TaskType) {
        return TaskType.SimpleTaskBase;
    }

    /// @notice Configures the task for SimpleTaskBase type tasks.
    /// Overrides the configureTask function in the MultisigTask contract.
    /// For SimpleTaskBase, we need to configure the simple address registry.
    function _configureTask(string memory taskConfigFilePath)
        internal
        virtual
        override
        returns (AddressRegistry addrRegistry_, IGnosisSafe parentMultisig_, address multicallTarget_)
    {
        multicallTarget_ = MULTICALL3_ADDRESS;

        simpleAddrRegistry = new SimpleAddressRegistry(taskConfigFilePath);
        addrRegistry_ = AddressRegistry.wrap(address(simpleAddrRegistry));

        parentMultisig_ = IGnosisSafe(simpleAddrRegistry.get(templateConfig.safeAddressString));
    }

    /// @notice Empty override to satisfy the MultisigTask contract. May include common logic at a later date.
    function _templateSetup(string memory, address) internal virtual override {}

    /// @notice Sets the allowed storage keys.
    function _setAllowedStorageAccesses() internal virtual override {
        for (uint256 i = 0; i < templateConfig.allowedStorageKeys.length; i++) {
            _allowedStorageAccesses.add(simpleAddrRegistry.get(templateConfig.allowedStorageKeys[i]));
        }
    }

    /// @notice Sets the allowed balance changes.
    function _setAllowedBalanceChanges() internal virtual override {
        for (uint256 i = 0; i < templateConfig.allowedBalanceChanges.length; i++) {
            _allowedBalanceChanges.add(simpleAddrRegistry.get(templateConfig.allowedBalanceChanges[i]));
        }
    }
}
