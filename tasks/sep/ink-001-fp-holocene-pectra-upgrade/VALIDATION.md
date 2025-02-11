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
  **After**: `0x000000000000000000000000e562e81d08cd5e212661ef961b4069456e426c56` <br/>
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x860e626c700AF381133D9f4aF31412A2d1DB3D5d "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000000000000000000000000000000000000000000000`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000a8808360f7bc16da81938e5c29400d18bea651c4` <br/>
  **After**: `0x0000000000000000000000004a0973e21274c4d939c84ac8b98d4308b7c9e249` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x860e626c700AF381133D9f4aF31412A2d1DB3D5d "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
  Before this task has been executed, you will see that the returned address is `0x000000000000000000000000a8808360f7bc16da81938e5c29400d18bea651c4`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.

## Verify Absolute Prestate
You can verify the absolute prestate 0x03dfa3b3ac66e8fae9f338824237ebacff616df928cf7dada0e14be2531bc1f4 by running the following command in the root of the monorepo:

make reproducible-prestate

You should expect the following output at the end of the command:

- **Cannon Absolute prestate hash**: 
0x03dfa3b3ac66e8fae9f338824237ebacff616df928cf7dada0e14be2531bc1f4

- **Cannon64 Absolute prestate hash**: 
0x03f83792f653160f3274b0888e998077a27e1f74cb35bcb20d86021e769340aa

- **CannonInterop Absolute prestate hash**: 
0x03b7658b889796c1e372f57439e48eb46a5b008f6e6a4b7e5c8c2d3bddffa797
