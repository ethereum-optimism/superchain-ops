pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

import {GasConfigTemplate} from "src/fps/example/template/GasConfigTemplate.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

/// @title IncorrectGasConfigTemplate1
/// @notice allowed storage write to incorrect address
contract IncorrectGasConfigTemplate1 is GasConfigTemplate {
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        /// wrong address
        storageWrites[0] = "SystemConfigOwner";
        return storageWrites;
    }
}
