pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

import {GasConfigTemplate} from "src/improvements/template/GasConfigTemplate.sol";
import {AddressRegistry as Addresses} from "src/improvements/AddressRegistry.sol";

/// @title IncorrectGasConfigTemplate2
/// @notice not all allowed storages writes are written to
contract IncorrectGasConfigTemplate2 is GasConfigTemplate {
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        /// expected to be written to
        storageWrites[0] = "SystemConfigOwner";
        storageWrites[1] = "SystemConfigProxy";
        return storageWrites;
    }
}
