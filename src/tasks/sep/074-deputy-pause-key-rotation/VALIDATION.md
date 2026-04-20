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
> Domain Hash: 0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb
> Message Hash: 0xe237ee9c4707924772b6226d8fb30747291a70190ba5508ac61b89871da26f85

## State Overrides

The following state overrides should be seen:

### `0xdee57160aafcf04c34c887b5962d0a69676d3c8b` (The Optimism Foundation Upgrade Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

### `0xc10dac07d477215a1ebebae1dd0221c1f5d241d2` (DeputyPauseModule)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Before:** `0x0000000000000000000000006a07d585eddba8f9a4e17587f4ea5378de1c3bac`
  - **After:** `0x0000000000000000000000008d2aae4009418ef6d83f1f2c90d4dac3ce2b5d4f`
  - **Summary:**
  - **Detail:**

**Update the previous Deputy with 0x6a07d585eddba8f9a4e17587f4ea5378de1c3bac to the new Deputy 0x8D2AAe4009418Ef6D83F1F2c90D4dAc3cE2b5D4f.**

---

### `0xdee57160aafcf04c34c887b5962d0a69676d3c8b` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `69`
  - **After:** `70`
  - **Summary:** nonce
  - **Detail:**

This updates the previous deputy `0xc10dac07d477215a1ebebae1dd0221c1f5d241d2` to `0x8D2AAe4009418Ef6D83F1F2c90D4dAc3cE2b5D4f`.
