# Validation

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
> Message Hash: 0xafab6e4cffa2647bb9f26cf85d2cb60c7ad6b9a2d4904abd7ac0f0af4279958a

## State Overrides

The following state overrides should be seen:

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

### `0x837de453ad5f21e89771e3c06239d8236c0efd5e` (Foundation Operations Safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `11`
  - **After:** `12`
  - **Summary:** nonce
  - **Detail:**

This updates the nonce of the Foundation Operations Safe.

---

### `0xc6f7c07047ba37116a3fdc444afb5018f6df5758` (DeputyPauseModule)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Before:** `0x0000000000000000000000006a07d585eddba8f9a4e17587f4ea5378de1c3bac`
  - **After:** `0x0000000000000000000000008d2aae4009418ef6d83f1f2c90d4dac3ce2b5d4f`
  - **Summary:**
  - **Detail:**

This updates the previous deputy `0x6A07d585eddBa8F9A4E17587F4Ea5378De1c3bAc` to `0x8D2AAe4009418Ef6D83F1F2c90D4dAc3cE2b5D4f`.
