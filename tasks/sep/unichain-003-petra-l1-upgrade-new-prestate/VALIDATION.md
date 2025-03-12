# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the below hashes match what is on your ledger.
> - Domain hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message hash: `0x9bca7891bcf169d6572e1e5ecd53bc542f53455ab247859ccb3012f21278632a`
## Verify new absolute prestate

Please verify that the new absolute prestate is set correctly to `0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01
`. See [Petra notice](https://docs.optimism.io/notices/pectra-changes#verify-the-new-absolute-prestate) in docs for more details. 

You can verify this absolute prestate by running the following [command](https://github.com/ethereum-optimism/optimism/blob/6819d8a4e787df2adcd09305bc3057e2ca4e58d9/Makefile#L133-L135) in the root of the monorepo:

```bash
make reproducible-prestate
```

You should expect the following output at the end of the command:

```bash
Cannon Absolute prestate hash: 
0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01
Cannon64 Absolute prestate hash: 
0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405
CannonInterop Absolute prestate hash: 
0x03673e05a48799e6613325a3f194114c0427d5889cefc8f423eed02dfb881f23
```


## State Changes

Note: The changes listed below do not include safe nonce updates or liveness guard related changes.

### `0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000003d914ba460e0bbf0b9bca35d65f9fc8e0bcb1c9d` <br/>
  **After**: `0x0000000000000000000000001Ca07eBBEd295C581c952Be0eB23E636aed9a2d0` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the new implementation is set using
  `cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 0`.

### `0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x00000000000000000000000061d1d2dffe0c1e3e200b27ae3874190158802fbb` <br/>
  **After**: `0x00000000000000000000000098b3cEA8dc27f83a6b8384F25A8eca52613A7182` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the new implementation is set using
  `cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 1`.
