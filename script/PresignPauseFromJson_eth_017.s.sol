// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PresignPauseFromJson as OriginalPresignPauseFromJson} from "./PresignPauseFromJson.s.sol";
import {console} from "forge-std/console.sol";

/// @title PresignPauseFromJson_eth_017
/// @notice This script is intended for one time use, and can be deleted after the tasks/eth/017-presign-pause runbook is completed.
contract PresignPauseFromJson_eth_017 is OriginalPresignPauseFromJson {
    address guardianSafe = vm.envAddress("GUARDIAN_SAFE_ADDR");

    /// @notice Adds the new DeputyGuardianModule to the guardianSafe to the simulation state.
    function _addMultipleGenericOverrides()
        internal
        view
        override
        returns (SimulationStateOverride[] memory overrides_)
    {
        overrides_ = new SimulationStateOverride[](1);
        overrides_[0] = _addGuardianSafeOverrides();
    }

    /// @notice Inserts the DeputyGuardianModule into the Guardian Safe's modules list
    function _addGuardianSafeOverrides() internal view returns (SimulationStateOverride memory override_) {
        address deputyGuardianModule = vm.envAddress("DEPUTY_GUARDIAN_MODULE_ADDR");
        override_.contractAddress = guardianSafe;
        override_.overrides = new SimulationStorageOverride[](2);
        // Ensure the sentinel module (`address(0x01)`) is pointing to the `DeputyGuardianModule`
        // This is `modules[0x1]`, so the key can be derived from
        // `cast index address 0x0000000000000000000000000000000000000001 1`.
        override_.overrides[0] = SimulationStorageOverride({
            key: keccak256(abi.encode(bytes32(uint256(1)), bytes32(uint256(1)))),
            value: bytes32(uint256(uint160(deputyGuardianModule)))
        });

        // Ensure the DeputyGuardianModule is pointing to the sentinel module.
        override_.overrides[1] = SimulationStorageOverride({
            key: keccak256(abi.encode(bytes32(uint256(uint160(deputyGuardianModule))), bytes32(uint256(1)))),
            value: bytes32(uint256(1))
        });
    }
}
