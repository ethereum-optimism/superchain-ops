# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
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
> ### SystemConfigOwner (`0x1A18bd2A868898EDDe75C54013baCc1938d399aC`)
>
> - Domain Hash:  `0xc74dc80f1d9c49ad237fba0d91fa570b6c5132c0472e23ecef5f5b6de1aa33c7`
> - Message Hash: `0x771bd1bbd603451c2a4e378054daa168c353d10b3fa6fa97306dbb2597ca3d73`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x83c7e3167f37968f8c6f17dbb119fbb1a59bdc82fd5935a4f5ad9bb03d063888`

## Understanding Task Calldata

The command to encode the calldata is:

### Inputs to `SystemConfig.setGasLimit(uint64 _gasLimit)`

This function is called with the following inputs:

- `_gasLimit`: 60_000_000

Command to encode:

```bash
cast calldata "setGasLimit(uint64)" 60000000
```

Resulting calldata:
```
0xb40a817c0000000000000000000000000000000000000000000000000000000003938700
```

### Inputs to `SystemConfig.setEIP1559Params(uint32 _denominator, uint32 _elasticity)`

This function is called with the following inputs:

- `_denominator`: 250
- `_elasticity`: 6

Command to encode:

```bash
cast calldata "setEIP1559Params(uint32,uint32)" 250 6
```

Resulting calldata:
```
0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006
```
### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3Value()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall SystemConfig tx_1:

- `target`: [0xbc3e62ab4a2137702d5b963028905d69fecef37c](https://github.com/ethereum-optimism/devnets/blob/main/betanets/rehearsal-1-bn/op-deployer/state.json#L127) - rehearsal-1-bn-0 SystemConfig
- `allowFailure`: false
- `value`: 0
- `callData`: `0xb40a817c0000000000000000000000000000000000000000000000000000000003938700` (output from the previous section)

Call3 struct for Multicall3DelegateCall SystemConfig tx_2:

- `target`: [0xbc3e62ab4a2137702d5b963028905d69fecef37c](https://github.com/ethereum-optimism/devnets/blob/main/betanets/rehearsal-1-bn/op-deployer/state.json#L127) - rehearsal-1-bn-0 SystemConfig
- `allowFailure`: false
- `value`: 0
- `callData`: `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0xbc3e62ab4a2137702d5b963028905d69fecef37c,false,0,0xb40a817c0000000000000000000000000000000000000000000000000000000003938700),(0xbc3e62ab4a2137702d5b963028905d69fecef37c,false,0,0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006)]"
```

The resulting calldata sent from the `SystemConfigOwner safe` is thus:
```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000120000000000000000000000000bc3e62ab4a2137702d5b963028905d69fecef37c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024b40a817c000000000000000000000000000000000000000000000000000000000393870000000000000000000000000000000000000000000000000000000000000000000000000000000000bc3e62ab4a2137702d5b963028905d69fecef37c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000044c0fd4b4100000000000000000000000000000000000000000000000000000000000000fa000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../../SINGLE_VALIDATION.md) file.

### Task State Changes

### `0x1a18bd2a868898edde75c54013bacc1938d399ac` (SystemConfigOwner (GnosisSafe)) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `0`
  - **After:** `1`
  - **Summary:** nonce
  - **Detail:** increments the safe's nonce
  
  ---
  
### `0xbc3e62ab4a2137702d5b963028905d69fecef37c` (SystemConfigProxy) 
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006a`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000000000000000000000000000000000006000000fa`
  - **Summary:** (`uint32`) eip1559Elasticity and eipDenominator change
  - **Detail:** eip1559Elasticity and eip1559Denominator share this same storage slot
      * Sets the eip1559Denominator to 250. Previously it was unset so its value was 0
      * Sets the eip1559Denominator to 6. Previously it was unset so its value was 0. ([Slot 106](#supplementary-material) contains these values)