// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {GasConfigTemplate} from "src/improvements/template/GasConfigTemplate.sol";

/// @title IncorrectGasConfigTemplate1
/// @notice allowed storage write to incorrect address
contract IncorrectGasConfigTemplate1 is GasConfigTemplate {
    function _taskStorageWrites(string memory) internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        /// wrong address
        storageWrites[0] = "SystemConfigOwner";
        return storageWrites;
    }
}
