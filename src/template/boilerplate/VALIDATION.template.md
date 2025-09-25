TODO: Please address all TODOs in this file before submitting your task to be reviewed.

# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Expected Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Normalized State Diff Hash Attestation](#normalized-state-diff-hash-attestation)
3. [Understanding Task Calldata](#understanding-task-calldata)
4. [Task State Changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### <TODO-enter-safe-name> (`<TODO-enter-safe-address>`)
>
> - Domain Hash:  `<TODO-enter-domain-hash>`
> - Message Hash: `<TODO-enter-message-hash>`

## Normalized State Diff Hash Attestation

The normalized state diff hash is a single fingerprint of all the onchain state changes your task would make if executed. We “normalize” the diff first (stable ordering and encoding) so the hash only changes when the actual intended state changes do. You **MUST** ensure that the normalized hash produced from your simulation matches the normalized hash in this document.

**Normalized hash:** `<TODO-enter-normalized-hash>`

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

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [<TODO NESTED OR SINGLE>-VALIDATION.md](../../../../../<TODO>) file.

### Task State Changes

TODO: You can copy the markdown state changes printed in the terminal and paste them here.