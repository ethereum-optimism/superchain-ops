# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Safe: `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`
>
> - Domain Hash: `0xe84ad8db37faa1651b140c17c70e4c48eaa47a635e0db097ddf4ce1cc14b9ecb`
> - Message Hash: `0xa5b581bbbdd908f535d8a3ba49d91fa41e828e735a918fe3832179e85359dfef`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xe8483eb5042b04bf0e41e7b763ac747f03f484a8af6ba9773cf11041fd8b94a4`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the new deputy pause module to be enabled.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `safe.disableModule()`

`safe.disableModule()` function is called with the address to be removed and the previous module:

The address of the module to be removed: 0xfd7E6Ef1f6c9e4cC34F54065Bf8496cE41A4e2e8
The address of the previous module: 0xc10dac07d477215a1ebebae1dd0221c1f5d241d2

Thus, the command to encode the calldata is:

```bash
cast calldata 'disableModule(address, address)' "0xc10dac07d477215a1ebebae1dd0221c1f5d241d2" "0xfd7E6Ef1f6c9e4cC34F54065Bf8496cE41A4e2e8"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3Value()` function.

This function is called with a tuple of four elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E](https://github.com/ethereum-optimism/superchain-registry/blob/744d7764c475f85b5abbaa70c6c461279c195190/validation/standard/standard-config-roles-sepolia.toml#L1) - Sepolia Guardian Safe
- `allowFailure`: false
- `value`: 0
- `callData`: `0xe009cfde000000000000000000000000c10dac07d477215a1ebebae1dd0221c1f5d241d2000000000000000000000000fd7e6ef1f6c9e4cc34f54065bf8496ce41a4e2e8` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E,false,0,0xe009cfde000000000000000000000000c10dac07d477215a1ebebae1dd0221c1f5d241d2000000000000000000000000fd7e6ef1f6c9e4cc34f54065bf8496ce41a4e2e8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000007a50f00e8d05b95f98fe38d8bee366a7324dcf7e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000044e009cfde000000000000000000000000c10dac07d477215a1ebebae1dd0221c1f5d241d2000000000000000000000000fd7e6ef1f6c9e4cc34f54065bf8496ce41a4e2e800000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in Action Plan section of the Governance proposal.

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

### Task State Changes

### `0x837de453ad5f21e89771e3c06239d8236c0efd5e` (FoundationOperationsSafe (GnosisSafe))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `5`
  - **After:** `6`
  - **Summary:** nonce
  - **Detail:**

- **Key:**          `0x3f5c1ee1d80a78eda1e233ed173406be4155e5d8a5edbebf8f522080d34dc1e3`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** Removing the DPM from the linked list.
  - **Detail:**  Setting the previous cursor to the zero address as the DPM was the last module in the linked list.

- **Key:**          `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f`
  - **Before:** `0x000000000000000000000000c6f7c07047ba37116a3fdc444afb5018f6df5758`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** Removing the DPM from the linked list.
  - **Detail:** Setting the cursor to the SENTINEL_MODULE (0x1) where the DPM was previously located.

### Nonce increments

The only other state change are one nonce increment:

- `0xf13D09eD3cbdD1C930d4de74808de1f33B6b3D4f` - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe).
