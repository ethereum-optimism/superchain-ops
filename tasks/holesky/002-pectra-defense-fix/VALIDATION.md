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

### `0x45b52AFe0b60f5aB1a2657b911b57DE0c42e5E50` (`AnchorStateRegistryProxy`)

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x630253c5afc399cbeaa927f56a7688ce21facfea555f1fe09c0004edfa05386b` <br/>
  **Meaning**: Set the anchor state output root for game type 0 to 0x630253c5afc399cbeaa927f56a7688ce21facfea555f1fe09c0004edfa05386b.

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb4a`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x1edf7` <br/>
  **Meaning**: Set the anchor state L2 block number for game type 0 to 126455.
