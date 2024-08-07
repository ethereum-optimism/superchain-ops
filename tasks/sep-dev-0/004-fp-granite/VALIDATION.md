# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

The only state changes should be made to the `DisputeGameFactoryProxy` game type implementations.

### `0x2419423c72998eb1c6c15a235de2f112f8e38eff` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  **Before**: `0x000000000000000000000000c06b6a93c4b8ef23e1fb535bb2dd80239ca433ac`
  **After**:  `0x00000000000000000000000050573970b291726B881b204eD9F3c1D507e504cD`
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0x2419423c72998eb1c6c15a235de2f112f8e38eff gameImpls(uint32)(address) 1`.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  **Before**: `0x0000000000000000000000003cdb0e38bc990c07eada1376248bb2a405ae3b9b`
  **After**:  `0x00000000000000000000000054416A2E28E8cbC761fbce0C7f107307991282e5`
  **Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0x2419423c72998eb1c6c15a235de2f112f8e38eff gameImpls(uint32)(address) 0`.
