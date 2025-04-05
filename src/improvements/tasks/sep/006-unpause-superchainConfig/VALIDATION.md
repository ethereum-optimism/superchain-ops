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
> ### Optimism Foundation
  Domain Hash:     TBD
  Message Hash:    TBD


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

### `0xC2Be75506d5724086DEB7245bd260Cc9753911Be` (SuperchainConfig)
Pause the SuperchainConfig by setting the paused slot to `1` that is `true`:
- **Key:** `0x54176ff9944c4784e5857ec4e5ef560a462c483bf534eda43f91bb01a470b1b6` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

  **Meaning:** Override the pause bit of the SuperchainConfig by setting the *paused slot* to `1` that is equal to `true`. Since we need to unpause the superchain that is already paused.

## State Changes

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

State changes:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:**  `0x0000000000000000000000000000000000000000000000000000000000000002`<br/>
  **Meaning:** The Safe nonce is updated.
- **Key:** `0x54176ff9944c4784e5857ec4e5ef560a462c483bf534eda43f91bb01a470b1b6` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:**  `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **Meaning:** The SuperchainConfig is unpaused by setting the *paused slot* to `0` that is equal to `false`. Since we need to unpause the superchain that is already paused.

