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

### `0xf971F1b0D80eb769577135b490b913825BfcF00B` (`AnchorStateRegistryProxy`)

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x3dd61be7c3e870294e842a0e3a7150fb5b73539260a9ec55d59151ba5f2201e9` <br/>
  **Meaning**: Set the anchor state output root for game type 0 to 0x3dd61be7c3e870294e842a0e3a7150fb5b73539260a9ec55d59151ba5f2201e9.

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb4a`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x67c6c4` <br/>
  **Meaning**: Set the anchor state L2 block number for game type 0 to 6801092.
