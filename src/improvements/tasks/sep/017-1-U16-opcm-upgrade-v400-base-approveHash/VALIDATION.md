TODO: Please address all TODOs in this file before submitting your task to be reviewed.

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
> ### Base Operations (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)
>
> - Domain Hash:  `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x991864d066c0ca3bb70d5aff303a6e54f7a4629799e39283b25406c5648860a9`
>
> ### Base Security Council (`0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`)
>
> - Domain Hash:  `0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23`
> - Message Hash: `0xfa24aa4f050f4ea1c3f457b77bf8382392c3042179235128aaaf8e283c465abe`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xbc406746264721a96c4956d8024dd6f509f6d966d457d1d5f827d4de6304185d`

## Understanding Task Calldata

The command to encode the calldata is:

```sh
# Encode the approve hash call for the hash that needs to be approved for task 017-2-U16-opcm-upgrade-v400-base.
cast calldata \
  "approveHash(bytes32)" \
  0x4769c1cfaa9cb7b373313abe3fa6469a2a1e756b059a74a141511355ff4f14b2

# This will print out the calldata for the approveHash call:
# 0xd4d9bdcd4769c1cfaa9cb7b373313abe3fa6469a2a1e756b059a74a141511355ff4f14b2

# Now encode the multicall payload, where `0x0fe884546476dDd290eC46318785046ef68a0BA9` is
# the address of the L1 ProxyAdmin Owner for Base.
cast calldata \
  "aggregate3Value((address,bool,uint256,bytes)[])" \
  '[(0x0fe884546476dDd290eC46318785046ef68a0BA9,false,0,0xd4d9bdcd4769c1cfaa9cb7b373313abe3fa6469a2a1e756b059a74a141511355ff4f14b2)]'
```

The resulting calldata:

```text
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000fe884546476ddd290ec46318785046ef68a0ba90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024d4d9bdcd4769c1cfaa9cb7b373313abe3fa6469a2a1e756b059a74a141511355ff4f14b200000000000000000000000000000000000000000000000000000000
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

#### `0x0fe884546476ddd290ec46318785046ef68a0ba9` (Base Operations Safe) - Chain ID: 11763072

- **Key:** `0x3cb894e4fceae49273c232ca8e3f156b944a12b10d7de24e1d7b2e25057d1e8b`
- **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
- **Summary:** This is setting the approved hash for the Base Operations safe. You can compute the slot using ....
- **Summary:** `approveHash(bytes32)` called on ProxyAdminOwner by Base Nested Safe multisig.

  ---

#### `0x0fe884546476ddd290ec46318785046ef68a0ba9` (Base Security Council Safe) - Chain ID: 11763072

- **Key:** `todo`
- **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
- **Summary:** This is setting the approved hash for the Base Security Council safe. You can compute the slot using ...
- **Detail:**

  ---

#### `0x646132a1667ca7ad00d36616afba1a28116c770a` (BaseNested Safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
- **Decoded Kind:** `uint256`
- **Before:** `6`
- **After:** `7`
- **Summary:** nonce
- **Detail:**
