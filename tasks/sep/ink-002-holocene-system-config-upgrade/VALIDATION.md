# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x05C993e60179f28bF649a2Bb5b00b5F4283bD525` (`SystemConfigProxy`)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000ccdd86d581e40fb5a1c77582247bc493b6c8b169`
  **After**: `0x00000000000000000000000033b83e4c305c908b2fc181dda36e230213058d7d`
  **Meaning**: Updates the `SystemConfig` proxy implementation.
