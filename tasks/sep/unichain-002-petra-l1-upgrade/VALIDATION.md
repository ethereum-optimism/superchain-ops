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

### `0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000b3ec5385110879ac592fc06de30479f688340dd2` <br/>
  **After**: `0x000000000000000000000000517AE9d74dbB9c7df6F3277225543BE2DCeD5a87` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the new implementation is set using
  `cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 0`.

### `0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000a83353016019cc8153c6abea91f7989a5b1d4569` <br/>
  **After**: `0x000000000000000000000000652f0D5aB7d145C0EdB86a0B4923F2f150a5482f` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the new implementation is set using
  `cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 1`.
