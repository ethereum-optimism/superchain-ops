// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PresignPauseFromJson as OriginalPresignPauseFromJson} from "script/PresignPauseFromJson.s.sol";
import {console} from "forge-std/console.sol";

contract PresignPauseFromJson is OriginalPresignPauseFromJson {
    address securityCouncil = 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03;

    // 1. Set the Guardian on the SuperchainConfig to the Security Council
    function _addGenericOverrides2() internal view override returns (SimulationStateOverride memory override_) {
        bytes32 guardianSlot = bytes32(uint256(keccak256("superchainConfig.guardian")) - 1);

        override_.contractAddress = vm.envAddress("SUPERCHAIN_CONFIG_ADDR");
        override_.overrides = new SimulationStorageOverride[](1);
        override_.overrides[0] =
            SimulationStorageOverride({key: guardianSlot, value: bytes32(uint256(uint160(securityCouncil)))});
    }

    function _addGenericOverrides3() internal view override returns (SimulationStateOverride memory override_) {
        // 1. install the DGM on the Security Council
        address dgm = vm.envAddress("DEPUTY_GUARDIAN_MODULE_ADDR");
        override_.contractAddress = securityCouncil;
        override_.overrides = new SimulationStorageOverride[](2);
        //   The sentinel module (`address(0x01)`) is now pointing to the `DeputyGuardianModule` at [`0x4220C5deD9dC2C8a8366e684B098094790C72d3c`](https://sepolia.etherscan.io/address/0x4220C5deD9dC2C8a8366e684B098094790C72d3c).
        //   This is `modules[0x1]`, so the key can be derived from `cast index address 0x0000000000000000000000000000000000000001 1`.
        override_.overrides[0] = SimulationStorageOverride({
            key: 0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f,
            value: bytes32(uint256(uint160(dgm)))
        });

        // status: failing consistently. not sure why.
        // tenderly says it's becuase modules[msg.sender] == 0
        // but that doesn't look right to me.
        // try updating input.json just to call getModulesPaginated to see what you get with these overrides.
        console.log("key");
        console.logBytes32(keccak256(abi.encode(bytes32(uint256(uint160(dgm))), bytes32(uint256(1)))));
        override_.overrides[1] = SimulationStorageOverride({
            key: keccak256(abi.encode(bytes32(uint256(uint160(dgm))), bytes32(uint256(1)))),
            value: bytes32(uint256(1))
        });
    }
}
