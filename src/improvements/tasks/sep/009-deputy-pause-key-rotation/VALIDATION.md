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
> Message Hash: 0xfc232e99f109db09a90ec0a319406d8e3df078659b05aeac83b22bdc64a18801

## State Overrides

The following state overrides should be seen:

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000002`<br/>
  **Meaning:** Override the nonce with the value of the current nonce of the safe. This is not required by this is present in the current version of the superchain for now and would be fixed in the future upgrade.

## State Changes

### `0x837de453ad5f21e89771e3c06239d8236c0efd5e` (Foundation Operations Safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `2`
  - **After:** `3`
  - **Summary:** nonce
  - **Detail:**

This update the nonces of the Foundation Operations safes.

---

### `0xc6f7c07047ba37116a3fdc444afb5018f6df5758` (DeputyPauseModule)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Before:** `0x000000000000000000000000fcb2575ab431a175669ae5007364193b2d298dfe`
  - **After:** `0x0000000000000000000000006a07d585eddba8f9a4e17587f4ea5378de1c3bac`
  - **Summary:**
  - **Detail:**

This update the previous deputy `0xfcb2575ab431a175669ae5007364193b2d298dfe` to `0x6a07d585eddba8f9a4e17587f4ea5378de1c3bac`.
