# Validaton

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Optimism Foundation Operation Safe
>
> Domain Hash: 0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890
> Message Hash: 0xf6e6c1d0a16b57ac611b89e4fbbe34082aecc4ef793a71401ab5e38c9d288369

## State Overrides

The following state overrides should be seen:

### `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a` (Foundation Operations Safe) - Chain ID: 10

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `104`
  - **After:** `105`
  - **Summary:** Increase the nonce after execution from 104 to 105.
- **Key:** `0x72524c5f4c3db4bf005b429ccfc4e864f1577d3c25909f510c6a4f9fa4c5783a`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**
  - **Detail:** Add the [DeputyPauseModule](https://etherscan.io/address/0x126a736b18e0a64fba19d421647a530e327e112c#code) `0x126a736B18E0a64fBA19D421647A530E327E112C` by _closing_ the linked list by the `SENTINEL_MODULES` (0x1). Thus `0x126a736B18E0a64fBA19D421647A530E327E112C` -> `0x1`. Key can be derived from `cast index address 0x126a736B18E0a64fBA19D421647A530E327E112C 1`.
- **Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  - **After:** `0x000000000000000000000000126a736b18e0a64fba19d421647a530e327e112c`
  - **Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyPauseModule` at [`0x126a736B18E0a64fBA19D421647A530E327E112C`](https://etherscan.io/address/0x126a736b18e0a64fba19d421647a530e327e112c#code). This is `modules[0x1]`, so the key can be derived from `cast index address 0x0000000000000000000000000000000000000001 1`.
