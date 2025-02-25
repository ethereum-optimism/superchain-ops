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
  **After**: `0x0000000000000000000000003d914Ba460E0bBf0b9Bca35d65f9fc8e0bcB1C9d` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the new implementation is set using
  `cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 0`.

### `0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000a83353016019cc8153c6abea91f7989a5b1d4569` <br/>
  **After**: `0x00000000000000000000000061D1d2DFfe0C1e3E200b27ae3874190158802Fbb` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the new implementation is set using
  `cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 1`.


## Verify new absolute prestate

Please verify that the new absolute prestate is set correctly to `0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd`. See [Petra notice](https://docs.optimism.io/notices/pectra-changes#verify-the-new-absolute-prestate) in docs for more details. 

You can verify this absolute prestate by running the following [command](https://github.com/ethereum-optimism/optimism/blob/6819d8a4e787df2adcd09305bc3057e2ca4e58d9/Makefile#L133-L135) in the root of the monorepo:

```bash
make reproducible-prestate
```

You should expect the following output at the end of the command:

```bash
Cannon Absolute prestate hash: 
0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd
Cannon64 Absolute prestate hash: 
0x03a7d967025dc434a9ca65154acdb88a7b658147b9b049f0b2f5ecfb9179b0fe
CannonInterop Absolute prestate hash: 
0x0379d61de1833af6766f07b4ed931d85b3f6282508bbcbf9f4637398d97b61c1
```
