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
> ### Unichain Upgrade Safe (Chain Governor) (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`)
>
> - Domain Hash:  `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0x3c7a84f52b9351a415da72b96f122777f4d5cd59ea84bf78d795ad8b76e582be`
>
> ### Optimism Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x3aec83315afa8668cec3e78736c1a560003a9890cad88cc725360e70f17101da`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x3aec83315afa8668cec3e78736c1a560003a9890cad88cc725360e70f17101da`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x569e75fc77c1a856f6daaf9e69d8a9566ca34aa47f9133711ce065a571af0cfd`

## Understanding Task Calldata

The command to encode the calldata is:

TODO: Explain with commands how to encode the calldata. You may not need to do this section if the upgrade isn't part of a governance proposal.

The resulting calldata:
```
TODO: add calldata here
```

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

  ---
  
### `0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2` (OptimismPortal2) - Chain ID: 130
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Decoded Kind:** `struct ResourceMetering.ResourceParams`
  - **Before:** ``
  - **After:** ``
  - **Summary:** params
  - **Detail:** 
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x6d5b183f538abb8572f5cd17109c617b994d5833` (ProxyAdminOwner (GnosisSafe)) - Chain ID: 130
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `6`
  - **After:** `7`
  - **Summary:** nonce
  - **Detail:** 
  
**<TODO: Insert links for this state change then remove this line.>**