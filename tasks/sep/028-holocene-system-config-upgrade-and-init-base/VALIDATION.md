# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (`GnosisSafeProxy`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before**: `0x000000000000000000000000000000000000000000000000000000000000000b`
  - **After**: `0x000000000000000000000000000000000000000000000000000000000000000c`
  - **Meaning**: Increments the `GnosisSafeProxy`'s `nonce`.

### `0xf272670eb55e895584501d564AfEB048bEd26194` (`SystemConfigProxy`)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Before**: `0x00000000000000000000000031aad1062c25ce545c14bd9ee64dedef6c6b6fac`
  - **After**:  `0x00000000000000000000000033b83e4c305c908b2fc181dda36e230213058d7d`
  - **Meaning**: Updates the `SystemConfig`'s implementation to version 2.3.0 at `0x33b83E4C305c908B2Fc181dDa36e230213058d7d`.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  - **Before**: `0x0000000000000000000000000000000000000000000000000000000003938700`
  - **After**: `0x00000000000000000000000000000000000a118b0000044d0000000003938700`
  - **Meaning**: Sets the new `SystemConfig`'s variables `blobbasefeeScalar` to `659851` and `basefeeScalar` to `1101`.

- **Key**: `0x000000000000000000000000000000000000000000000000000000000000006a`
  - **Before**: `0x000000000000000000000000000000000000000000000000000000000042b1d7`
  - **After**: `0x0000000000000000000000000000000000000000000000000000000400000001`
  - **Meaning**: Sets the new `SystemConfig`'s variables `eip1559Denominator` to `1` and `eip1559Elasticity` to `4`.