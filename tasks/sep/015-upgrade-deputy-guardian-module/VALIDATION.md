# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E` (Guardian `GnosisSafe`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Meaning**: The Guardian nonce is incremented twice. For `disableModule` and `enableModule` operations.

- **Key**: `TODO` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets the `modules` mapping key for the new `DeputyGuardianModule` to `SENTINEL_MODULES`.

- **Key**: `0x33da99a51c1b688d5178595aac5396d1190fb91dc97bd61605c54cce5a81e8f8` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Clears the `modules` mapping key for the old `DeputyGuardianModule`.
    ```
    cast index address 0x4220C5deD9dC2C8a8366e684B098094790C72d3c 1
    0x33da99a51c1b688d5178595aac5396d1190fb91dc97bd61605c54cce5a81e8f8 
    ```
    where `0x4220C5deD9dC2C8a8366e684B098094790C72d3c` is the old `DeputyGuardianModule` and the `modules` mapping is located on the second slot.

- **Key**: `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
  **Before**: `0x0000000000000000000000004220c5ded9dc2c8a8366e684b098094790c72d3c` <br/>
  **After**: `TODO` <br/>
  **Meaning**: Sets the `modules` mapping key for `SENTINEL_MODULES` to the new `DeputyGuardianModule`.
    ```
    cast index address 0x0000000000000000000000000000000000000001 1
    0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f
    ```
    where `0x0000000000000000000000000000000000000001` is the `SENTINEL_MODULES` key and the `modules` mapping is located on the second slot.
