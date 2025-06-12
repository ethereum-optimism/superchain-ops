# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

The steps are:
1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Worldchain Proxy Admin Owner (`0x945185C01fb641bA3E63a9bdF66575e35a407837`)
>
> - Domain Hash:  `0x6faec9c52949ba8274340008df12c69faedd5c44e77f77c956d2ca8e4bcd877e`
> - Message Hash: `0x55faea00e974897c5afad9bdece6e4239df3b44a54dc03bab2f9172c5ab91c9c`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x468b869284297f167bc8a9e7589ccbd096c1fab043792a6e461b5ad8d30d556b`



# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../../SINGLE-VALIDATION.md) file

### Task State Changes
---

### [`0x3a987fe1cb587b0a1808cf9bb7cbe0e341838319`](https://github.com/ethereum-optimism/superchain-registry/blob/1ff0df40c7602761c55ab2cb693614ca0382bd64/superchain/configs/sepolia/worldchain.toml#L60) (ProxyAdmin) - Chain ID: 4801

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x945185C01fb641bA3E63a9bdF66575e35a407837`
  - **After:** [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/93c5073d233cb9011a95aebf275270fd00346400/validation/standard/standard-config-roles-sepolia.toml#L3)
  - **Summary:** ProxyAdmin owner update to new Superchain L1PAO

  ---
  
### [`0x8ec1111f67dad6b6a93b3f42dfbc92d81c98449a`](https://github.com/ethereum-optimism/superchain-registry/blob/1ff0df40c7602761c55ab2cb693614ca0382bd64/superchain/configs/sepolia/worldchain.toml#L64) (DisputeGameFactory) - Chain ID: 4801

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x945185C01fb641bA3E63a9bdF66575e35a407837`
  - **After:** [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/93c5073d233cb9011a95aebf275270fd00346400/validation/standard/standard-config-roles-sepolia.toml#L3)
  - **Summary:** DisputeGameFactory owner update to new Superchain L1PAO
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
    ```bash
    cast storage 0x8ec1111f67dad6b6a93b3f42dfbc92d81c98449a 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url sepolia
    # returns 0x000000000000000000000000945185c01fb641ba3e63a9bdf66575e35a407837
    cast call 0x8ec1111f67dad6b6a93b3f42dfbc92d81c98449a "owner()(address)" --rpc-url sepolia
    # returns 0x945185C01fb641bA3E63a9bdF66575e35a407837
    ```
  
  ---
  
### [`0x945185c01fb641ba3e63a9bdf66575e35a407837`](https://github.com/ethereum-optimism/superchain-registry/blob/1ff0df40c7602761c55ab2cb693614ca0382bd64/superchain/configs/sepolia/worldchain.toml#L44) (Proxy Admin Owner & Challenger GnosisSafe) - Chain ID: 4801

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `44` - (`cast --to-dec 0x2c` is `44`)
  - **After:** `45` - (`cast --to-dec 0x2d` is `45`)
  - **Summary:** nonce
  - **Detail:** Nonce update for the parent multisig.
  
  ---
  
### [`0xaeb3cfd5aaba01cfd12e6017a9a307a218cdd7e2`](https://sepolia.etherscan.io/address/0x552334Bf0B124bD89BFF744f33Ca7e49d44a80Ac#readContract#F37) (DelayedWETH) - Chain ID: 4801

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0`
  - **After:** [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/93c5073d233cb9011a95aebf275270fd00346400/validation/standard/standard-config-roles-sepolia.toml#L3)
  - **Summary:** Permissioned DelayedWETH owner update to new Superchain L1PAO
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
    ```bash
    cast storage 0xaeb3cfd5aaba01cfd12e6017a9a307a218cdd7e2 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url sepolia
    # returns 0x000000000000000000000000e78a0a96c5d6ae6c606418ed4a9ced378cb030a0
    cast call 0xaeb3cfd5aaba01cfd12e6017a9a307a218cdd7e2 "owner()(address)" --rpc-url sepolia
    # returns 0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0
    ```