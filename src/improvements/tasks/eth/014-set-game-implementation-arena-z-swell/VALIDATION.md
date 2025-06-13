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
> ### Security Council Safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x2b9983a6999685875490d9bd1cd78a6874d0cad24df19d3638968a1ffcb4ce27`
>
> ### Foundation Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x2b9983a6999685875490d9bd1cd78a6874d0cad24df19d3638968a1ffcb4ce27`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x9dcdb9f783102d6df1ab95c794b9d5b27ee7e7a653edc5b66be297e3b2ccadfd`

## Understanding Task Calldata

The command to encode the calldata is:

TODO: Explain with commands how to encode the calldata. You may not need to do this section if the upgrade isn't part of a governance proposal.

The resulting calldata:
```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000140000000000000000000000000658656a14afdf9c507096ac406564497d13ec754000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004414f6b1a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087690676786cdc8cca75a472e483af7c8f2f0f57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004414f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [<TODO NESTED OR SINGLE>-VALIDATION.md](../../../../../<TODO>) file.

### Task State Changes

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (ProxyAdminOwner (GnosisSafe)) - Chain ID: 10
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `19`
  - **After:** `20`
  - **Summary:** Nonce
  - **Detail:** Updates the nonce of the ProxyAdminOwner
  
### `0x658656a14afdf9c507096ac406564497d13ec754` (DisputeGameFactory) - Chain ID: 7897
  
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x000000000000000000000000733a80ce3baec1f27869b6e4c8bc0e358c121045`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** FaultDisputeGame Implementation
  - **Detail:** Resets the FDG implementation on Arena-Z Mainnet DisputeGameFactory to the zero address
  
### `0x87690676786cdc8cca75a472e483af7c8f2f0f57` (DisputeGameFactory) - Chain ID: 1923
  
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x0000000000000000000000002dabff87a9a634f6c769b983afbbf4d856add0bf`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** FaultDisputeGame Implementation
  - **Detail:** Resets the FDG implementation on Swell Mainnet DisputeGameFactory to the zero address