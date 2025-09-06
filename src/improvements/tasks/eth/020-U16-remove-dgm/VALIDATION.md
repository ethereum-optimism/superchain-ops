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
> ### Nested Safe 1 (Security Council): `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x14ccefe3aaec9fb93aa84b7ec57c17f7ecdadda8d404eef2a016e102bbe52973`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x42d5667c70c60c637f572a18bafc540726816a0268592c22f0689eefca2f1521`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the new deputy pause module to be enabled.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `safe.disableModule()`

`safe.disableModule()` function is called with the address to be removed and the previous module:

The address of the module to be removed: 0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B
The address of the previous module: 0x76fc2f971fb355d0453cf9f64d3f9e4f640e1754

Thus, the command to encode the calldata is:

```bash
cast calldata 'disableModule(address, address)' "0x76fc2f971fb355d0453cf9f64d3f9e4f640e1754" "0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3Value()` function.

This function is called with a tuple of four elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2](https://github.com/ethereum-optimism/superchain-registry/blob/744d7764c475f85b5abbaa70c6c461279c195190/validation/standard/standard-config-roles-mainnet.toml#L1) - Guardian Safe
- `allowFailure`: false
- `value`: 0
- `callData`: `0xe009cfde00000000000000000000000076fc2f971fb355d0453cf9f64d3f9e4f640e1754000000000000000000000000c6901f65369fc59fc1b4d6d6be7a2318ff38db5b` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2,false,0,0xe009cfde00000000000000000000000076fc2f971fb355d0453cf9f64d3f9e4f640e1754000000000000000000000000c6901f65369fc59fc1b4d6d6be7a2318ff38db5b)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000009f7150d8c019bef34450d6920f6b3608cefdaf20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000044e009cfde00000000000000000000000076fc2f971fb355d0453cf9f64d3f9e4f640e1754000000000000000000000000c6901f65369fc59fc1b4d6d6be7a2318ff38db5b00000000000000000000000000000000000000000000000000000000
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

### `0x09f7150d8c019bef34450d6920f6b3608cefdaf2` (Guardian (GnosisSafe)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `5`
  - **After:** `6`
  - **Summary:** nonce
  - **Detail:**

- **Key:**          `0x122c127b258a6e22748d3f3c38ae3a4c32252b46d3ad49e5d85acb3626c15d39`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** Removing the DGM from the linked list.
  - **Detail:** Setting the previous cursor to the zero address as the DGM was the last module in the linked list.

- **Key:**          `0xb59c18a81816f359656b617dbda1931931bffeb43b6469ce9d2b68e62ad8ff33`
  - **Before:** `0x000000000000000000000000c6901f65369fc59fc1b4d6d6be7a2318ff38db5b`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** Removing the DGM from the linked list.
  - **Detail:** Setting the cursor to the SENTINEL_MODULE (0x1) where the DGM was previously located.


- **Key:**          `0xe20ff0463b720bc23d1bb61ab6bc699ec8e28f58d4888b60e2e278967e6f053a`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** The `approvedHashes` mapping is updated.
