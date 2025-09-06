// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {GasConfigTemplate} from "test/tasks/mock/template/GasConfigTemplate.sol";

/// @title IncorrectGasConfigTemplate2
/// @notice not all allowed storages writes are written to
contract IncorrectGasConfigTemplate2 is GasConfigTemplate {
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        /// expected to be written to
        storageWrites[0] = "SystemConfigOwner";
        return storageWrites;
    }
}
