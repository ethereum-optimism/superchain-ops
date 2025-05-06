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
> ### Optimism Foundation Operations Safe
>
> Domain Hash: 0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890
> Message Hash: 0x10f7f7c354256471c1f285862cafadb3dccbacf23dd84abfb3de7642c5798e94

## State Overrides

The following state overrides should be seen:

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x000000000000000000000000000000000000000000000000000000000000006a`
  **Meaning:** Override the nonce with the value `106`, since we want to execute this task after the Base Upgrade.

- **Key:** `0x54176ff9944c4784e5857ec4e5ef560a462c483bf534eda43f91bb01a470b1b6`
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning:** Superchain pause status is overwritten to `1` since this is expected to be executed after a pause has been enabled.

## State Changes

### `0x95703e0982140d16f8eba6d158fccede42f04a4c`  (SuperchainConfig) - Chain ID: 10
- **Key:** `0x54176ff9944c4784e5857ec4e5ef560a462c483bf534eda43f91bb01a470b1b6`
  - **Decoded Kind:** `bool`
  - **Before:** `true`
  - **After:** `false`
  - **Summary:** Superchain pause slot that can be computed in chisel by: (`bytes32(uint256(keccak256("superchainConfig.paused")) - 1)`)  status changed from `true` to `false`.
  - **Detail:** Unstructured storage slot for the pause status of the superchain.

### `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`  (Challenger (GnosisSafe)) - Chain ID: 10

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `106`
  - **After:** `107`
  - **Summary:** Increase the nonce after execution of `1` from `106` to `107`.
  - **Detail:**
