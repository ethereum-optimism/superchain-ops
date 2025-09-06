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
> ### Optimism Foundation
>
> Domain Hash: 0xe84ad8db37faa1651b140c17c70e4c48eaa47a635e0db097ddf4ce1cc14b9ecb
> Message Hash: 0xf3a7b4d1889a291561a36dd6d4b0f303aafeb23506fb1c588133edb1deaedec5

## State Overrides

The following state overrides should be seen:

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **Meaning:** Override the nonce with the value of the current nonce of the safe. This is not required by this is present in the current version of the superchain for now and would be fixed in the future upgrade.

## State Changes

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

State changes:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000003`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000004`<br/>
  **Meaning:** The Safe nonce is updated.
- **Key:** `0x3f5c1ee1d80a78eda1e233ed173406be4155e5d8a5edbebf8f522080d34dc1e3` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **Meaning**: Add the [DeputyPauseModule](https://sepolia.etherscan.io/address/0xc6f7c07047ba37116a3fdc444afb5018f6df5758#code) `0xc6f7c07047ba37116a3fdc444afb5018f6df5758` by _closing_ the linked list by the `SENTINEL_MODULES` (0x1). Thus `0xc6f7c07047ba37116a3fdc444afb5018f6df5758` -> `0x1`. Key can be derived from `cast index address 0xc6f7c07047ba37116a3fdc444afb5018f6df5758 1`.
- **Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:** `0x000000000000000000000000c6f7c07047ba37116a3fdc444afb5018f6df5758`<br/>
  **Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyPauseModule` at [`0xc6f7c07047ba37116a3fdc444afb5018f6df5758`](https://sepolia.etherscan.io/address/0xc6f7c07047ba37116a3fdc444afb5018f6df5758). This is `modules[0x1]`, so the key can be derived from `cast index address 0x0000000000000000000000000000000000000001 1`.
