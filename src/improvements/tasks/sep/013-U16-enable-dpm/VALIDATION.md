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
> ### Nested Safe 1 (Council): `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xd08ffd9e319bd742ca7bf58356c145ec07c6068a671d3d8ed92bf89fe25c3411`
>
> ### Nested Safe 2 (Foundation): `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xac9761d0cd16b19a1a400fd186b9eb22000b6d2d3767f17b6a6bee9b1447954f`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xdb0bdc5a11f6f726112953663f44996c1ddf8164d9f8e73b978dd0ac13ddcacb`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the new deputy pause module to be enabled.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `safe.enableModule()`

`safe.enableModule()` function is called with the address of the new deputy pause module to be enabled:

New Deputy Pause Module Address: 0xc10dac07d477215a1ebebae1dd0221c1f5d241d2

Thus, the command to encode the calldata is:

```bash
cast calldata 'enableModule(address)' "0xc10dac07d477215a1ebebae1dd0221c1f5d241d2"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3Value()` function.

This function is called with a tuple of four elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E](https://github.com/ethereum-optimism/superchain-registry/blob/744d7764c475f85b5abbaa70c6c461279c195190/validation/standard/standard-config-roles-sepolia.toml#L1) - Sepolia Guardian Safe
- `allowFailure`: false
- `value`: 0
- `callData`: `0x610b5925000000000000000000000000c10dac07d477215a1ebebae1dd0221c1f5d241d2` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E,false,0,0x610b5925000000000000000000000000c10dac07d477215a1ebebae1dd0221c1f5d241d2)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000007a50f00e8d05b95f98fe38d8bee366a7324dcf7e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024610b5925000000000000000000000000c10dac07d477215a1ebebae1dd0221c1f5d241d200000000000000000000000000000000000000000000000000000000
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

### `0x7a50f00e8d05b95f98fe38d8bee366a7324dcf7e` (Guardian (GnosisSafe)) - Chain ID: 11011
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `6`
  - **After:** `7`
  - **Summary:** nonce
  - **Detail:** 
  
- **Key:**          `0x076f3dda6ab776db8482d7489f57d7a476c42f834ef63e2337ab108dc39e16be`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000fd7e6ef1f6c9e4cc34f54065bf8496ce41a4e2e8`
  - **Summary:**  Adding the new Deputy Pause Module to the linked list.
  - **Detail:**  We are adding the previous module to the linked list again as we replace the old reference with the new DPM.

- **Key:**          `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f`
  - **Before:** `0x000000000000000000000000fd7e6ef1f6c9e4cc34f54065bf8496ce41a4e2e8`
  - **After:** `0x000000000000000000000000c10dac07d477215a1ebebae1dd0221c1f5d241d2`
  - **Summary:** Adding the new Deputy Pause Module to the linked list.
  - **Detail:** We are adding the new Deputy Pause Module to the linked list by replacing the previous module with the new one.

### Nonce increments

The only other state change are two nonce increments:

- `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` - Security Council
- `0xf13D09eD3cbdD1C930d4de74808de1f33B6b3D4f` - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe).

And one liveness guard update update as we are doing a transaction:

- `0xc26977310bC89DAee5823C2e2a73195E85382cC7` - LivenessGuard