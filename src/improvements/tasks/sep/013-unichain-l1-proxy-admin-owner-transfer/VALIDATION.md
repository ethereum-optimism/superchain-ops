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
> - Domain Hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0x748137eeaf242540c565e0e66103043067e2f58ed036250c637ef517f7480942`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x0a017be1d930f7b5079e75abc1552e7554b413e43209999487a06ba1dbefac09`

## Understanding Task Calldata

The command to encode the calldata is:

```bash
cast calldata "transferOwnership(address)" "0x1Eb2fFc903729a0F03966B917003800b145F56E2"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:
- `target`: []() - // TODO
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
// TODO
cast calldata 'aggregate3((address,bool,bytes)[])' "[(,false,)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
// TODO
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-15-isthmus-hard-fork/9804) section of the Governance proposal.

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../../SINGLE-VALIDATION.md) file.

### Task State Changes

// TODO: Address all todos below and then remove this comment.

  ---
  
### `0x2bf403e5353a7a082ef6bb3ae2be3b866d8d3ea4`  (ProxyAdmin) - Chain ID: 1301
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0xd363339eE47775888Df411A163c586a8BdEA9dbf`
  - **After:** `0x1Eb2fFc903729a0F03966B917003800b145F56E2`
  - **Summary:** _owner
  - **Detail:** 
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0xd363339ee47775888df411a163c586a8bdea9dbf`  (ProxyAdminOwner (GnosisSafe)) - Chain ID: 1301
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `32`
  - **After:** `33`
  - **Summary:** nonce
  - **Detail:** 
  
**<TODO: Insert links for this state change then remove this line.>**