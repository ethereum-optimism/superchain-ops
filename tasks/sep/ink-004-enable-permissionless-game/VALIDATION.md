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

### `0x5c1d29C6c9C8b0800692acC95D700bcb4966A1d7` (`OptimismPortalProxy`)

- **Key**: `0x000000000000000000000000000000000000000000000000000000000000003b` <br/>
  **Before**: `0x000000000000000000000000000000000000000000000000670e7f2000000001` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000670e7f2000000000` <br/>
  **Meanning**: Updates the `respectedGameType` to `0` to use `FaultDisputeGame`.
