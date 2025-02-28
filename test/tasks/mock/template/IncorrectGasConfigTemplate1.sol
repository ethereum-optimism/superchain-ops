// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {GasConfigTemplate} from "src/improvements/template/GasConfigTemplate.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";

/// @title IncorrectGasConfigTemplate1
/// @notice allowed storage write to incorrect address
contract IncorrectGasConfigTemplate1 is GasConfigTemplate {
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        /// wrong address
        storageWrites[0] = "SystemConfigOwner";
        return storageWrites;
    }

    function _deployAddressRegistry(string memory configPath) internal override returns (AddressRegistry) {
        return new AddressRegistry(configPath);
    }
}
