// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PresignPauseFromJson as OriginalPresignPauseFromJson} from "script/PresignPauseFromJson.s.sol";
import {console} from "forge-std/console.sol";

contract PresignPauseFromJson is OriginalPresignPauseFromJson {
    address guardianSafe = vm.envAddress("GUARDIAN_SAFE_ADDR");

    /// @notice Sets the Guardian on the SuperchainConfig to the Security Council
    function _addGenericOverrides2() internal view override returns (SimulationStateOverride memory override_) {
        bytes32 guardianSlot = bytes32(uint256(keccak256("superchainConfig.guardian")) - 1);

        override_.contractAddress = vm.envAddress("SUPERCHAIN_CONFIG_ADDR");
        override_.overrides = new SimulationStorageOverride[](1);
        override_.overrides[0] =
            SimulationStorageOverride({key: guardianSlot, value: bytes32(uint256(uint160(guardianSafe)))});
    }

    /// @notice Inserts the DeputyGuardianModule into the Guardian Safe's modules list
    function _addGenericOverrides3() internal view override returns (SimulationStateOverride memory override_) {
        address deputyGuardianModule = vm.envAddress("DEPUTY_GUARDIAN_MODULE_ADDR");
        override_.contractAddress = guardianSafe;
        override_.overrides = new SimulationStorageOverride[](2);
        // Ensure the sentinel module (`address(0x01)`) is pointing to the `DeputyGuardianModule`
        // This is `modules[0x1]`, so the key can be derived from
        // `cast index address 0x0000000000000000000000000000000000000001 1`.
        override_.overrides[0] = SimulationStorageOverride({
            key: 0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f,
            value: bytes32(uint256(uint160(dgm)))
        });

        // Ensure the DeputyGuardianModule is pointing to the sentinel module.
        override_.overrides[1] = SimulationStorageOverride({
            key: keccak256(abi.encode(bytes32(uint256(uint160(deputyGuardianModule))), bytes32(uint256(1)))),
            value: bytes32(uint256(1))
        });
    }
}
