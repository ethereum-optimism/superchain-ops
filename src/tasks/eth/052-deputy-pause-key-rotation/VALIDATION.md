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
> Domain Hash: 0x2e5ad244d335c45fbace4ebd1736b0fad81b01591a2819baedad311ead5bce76
> Message Hash: 0xbb9508edc2cb54922dfdbd999b50b95622aa8be4475159ceb3d4a6306241f192

## State Overrides

The following state overrides should be seen:

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

### `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a` (Foundation Operations Safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `118`
  - **After:** `119`
  - **Summary:** nonce
  - **Detail:**

This updates the nonce of the Foundation Operations Safe.

---

### `0x126a736b18e0a64fba19d421647a530e327e112c` (DeputyPauseModule)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Before:** `0x000000000000000000000000352f1defb49718e7ea411687e850aa8d6299f7ac`
  - **After:** `0x0000000000000000000000002fa150379bf32b6d79eeb4ff9bd280e76049a87c`
  - **Summary:**
  - **Detail:**

This updates the previous deputy `0x352f1defB49718e7Ea411687E850aA8d6299F7aC` to `0x2fA150379bF32b6d79Eeb4ff9bD280E76049a87c`.
