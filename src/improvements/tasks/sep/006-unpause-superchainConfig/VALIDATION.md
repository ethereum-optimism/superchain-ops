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
  Domain Hash:     0xe84ad8db37faa1651b140c17c70e4c48eaa47a635e0db097ddf4ce1cc14b9ecb
  Message Hash:    0x2f09801a4332cfc98a8296db2438bf174c45d1d26e9be23a918f4d2cad0a745e


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

### `0x837de453ad5f21e89771e3c06239d8236c0efd5e (Unknown (GnosisSafe))`

#### Decoded State Change: 0
  - **Contract:**          `Unknown (GnosisSafe)`
  - **Chain ID:**          ``

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `1`
  - **After:** `2`

- **Summary:**           nonce
  - **Detail:**

Increase the nonce after the execution

  ---

### `0xc2be75506d5724086deb7245bd260cc9753911be (SuperchainConfig)`

#### Decoded State Change: 1
  - **Contract:**          `SuperchainConfig`
  - **Chain ID:**          `1946`

- **Key:**          `0x54176ff9944c4784e5857ec4e5ef560a462c483bf534eda43f91bb01a470b1b6`
  - **Decoded Kind:**      `bool`
  - **Before:** `true`
  - **After:** `false`

- **Summary:**           Superchain pause status changed from `true` to `false`. 
  - **Detail:**            Unstructured storage slot for the pause status of the superchain.




