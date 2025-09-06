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
> ### Single Safe Signer Data
>
> - Domain Hash: `0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890`
> - Message Hash: `0xe0ce4457fa888087c659f29829ffee2c3ee5460aecbb740cf1f1df38fcb65002`


## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x80cd4f80a0b81d472388007a8b9dff1236113b17aba56f37d27117d86126c869`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the new deputy pause module to be enabled.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `safe.disableModule()`

`safe.disableModule()` function is called with the address to be removed and the previous module:

The address of the module to be removed: 0x126a736B18E0a64fBA19D421647A530E327E112C
The address of the previous module: 0x0000000000000000000000000000000000000001

Thus, the command to encode the calldata is:

```bash
cast calldata 'disableModule(address, address)' "0x0000000000000000000000000000000000000001" "0x126a736B18E0a64fBA19D421647A530E327E112C"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3Value()` function.

This function is called with a tuple of four elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A](https://github.com/ethereum-optimism/superchain-registry/blob/744d7764c475f85b5abbaa70c6c461279c195190/validation/standard/standard-config-roles-mainnet.toml#L2) - Foundation Operations Safe
- `allowFailure`: false
- `value`: 0
- `callData`: `0xe009cfde0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000126a736b18e0a64fba19d421647a530e327e112c` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A,false,0,0xe009cfde0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000126a736b18e0a64fba19d421647a530e327e112c)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000044e009cfde0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000126a736b18e0a64fba19d421647a530e327e112c00000000000000000000000000000000000000000000000000000000
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

### `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a` (Foundation Operations Safe (GnosisSafe)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `108`
  - **After:** `109`
  - **Summary:** nonce
  - **Detail:**

- **Key:**          `0x72524c5f4c3db4bf005b429ccfc4e864f1577d3c25909f510c6a4f9fa4c5783a`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** Removing the DPM from the linked list.
  - **Detail:** Setting the previous cursor to the zero address as the DPM was the last module in the linked list.

- **Key:**          `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f`
  - **Before:** `0x000000000000000000000000126a736b18e0a64fba19d421647a530e327e112c`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** Removing the DPM from the linked list.
  - **Detail:** Setting the cursor to the SENTINEL_MODULE (0x1) where the DPM (0x126a736B18E0a64fBA19D421647A530E327E112C) was previously located.
