# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

Note: The changes listed below do not include safe nonce updates or liveness guard related changes.

### `0x87690676786cDc8cCA75A472e483AF7C8F2f0F57` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000002DabFf87A9a634f6c769b983aFBbF4D856aDD0bF` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the new implementation is set using
  `cast call 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57 "gameImpls(uint32)(address)" 0`.

### `0x87690676786cDc8cCA75A472e483AF7C8F2f0F57` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000a0cfbe3402d6e0a74e96d3c360f74d5ea4fa6893` <br/>
  **After**: `0x0000000000000000000000001380Cc0E11Bfe6b5b399D97995a6B3D158Ed61a6` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the new implementation is set using
  `cast call 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57 "gameImpls(uint32)(address)" 1`.
