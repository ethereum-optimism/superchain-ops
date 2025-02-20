# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (`SystemConfigProxy`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000066`
  **Before**: `0x00000000000000000000000000000000000000000000000000000000000c3c9d`
  **After**: `0x01000000000000000000000000000000000000000000000000000000000c3c9d`
  **Meaning**: Updates the scalar storage variable to reflect a scalar version of .

and

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000003938700`
  **After**: `0x0000000000000000000000000000000000000000000c3c9d0000000003938700`
  **Meaning**: Updates the basefeeScalar storage variable to 801949 (cast td 0x0). This shares a slot with the gasLimit which remains at 30000000 (cast td 0x0).

and

### `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` (`SystemConfigProxy`)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886`
  **After**: `0x000000000000000000000000ab9d6cb7a427c0765163a7f45bb91cafe5f2d375`
  **Meaning**: Updates the `SystemConfig` proxy implementation.
