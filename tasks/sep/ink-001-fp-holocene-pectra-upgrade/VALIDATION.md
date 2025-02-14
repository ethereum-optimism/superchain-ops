# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000323d727a1a147869cec0c02de1d4195d1b71f2eb` <br/>
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x860e626c700AF381133D9f4aF31412A2d1DB3D5d "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000000000000000000000000000000000000000000000`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000a8808360f7bc16da81938e5c29400d18bea651c4` <br/>
  **After**: `0x00000000000000000000000039228e51a12662d78de478bfa1930fc7595337d8` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x860e626c700AF381133D9f4aF31412A2d1DB3D5d "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
  Before this task has been executed, you will see that the returned address is `0x000000000000000000000000a8808360f7bc16da81938e5c29400d18bea651c4`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.

## Verify livenessGuard and Absolute Prestate

The **livenessGuard** address can be verified here https://github.com/ethereum-optimism/superchain-ops/blob/b17d3037c68e50f28ad19abf03bb952e507b3ebc/tasks/sep/006-2-sc-changes/VALIDATION.md?plain=1#L89 as it was set with the superchain-ops Sepolia task **006-2-sc-changes**

The following is based on the **op-program/v1.5.0-rc.2**

Absolute prestates can be checked in the Superchain Registry https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml

Absolute prestates for upcoming releases, not yet included in the above toml, can be manually verified in the root of the optimism monorepo.

To manually verify the prestate `0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd`, based on **op-program/v1.5.0-rc.2**, run the below command in the root of https://github.com/ethereum-optimism/optimism/tree/op-program/v1.5.0-rc.2:

make reproducible-prestate

You should expect the following output at the end of the command:

- **Cannon Absolute prestate hash**: 
`0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd`

- **Cannon64 Absolute prestate hash**: 
`0x03a7d967025dc434a9ca65154acdb88a7b658147b9b049f0b2f5ecfb9179b0fe`

- **CannonInterop Absolute prestate hash**: 
`0x0379d61de1833af6766f07b4ed931d85b3f6282508bbcbf9f4637398d97b61c1`
