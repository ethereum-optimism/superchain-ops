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
> - Message Hash: `0x1258b85745604e0f11dc973c64c26377d25d8830dc31e4c892ec15c3ba1af49a`
>
> ### Optimism Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x4f77242a5066291ced512e1b178d99a1e8c60ea904b1105a4bd8c03cd6cebb31`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x13377ce8026976b8eb9dd6a3c6041312f0cb87fdf2ab0dabf77298fa0274ce2f`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x90dea31693de63d864a36c1c762e159cc4f8b1357666580e0a295ecf70bf1f97`

## Understanding Task Calldata

The command to encode the calldata is:

```bash
cast calldata "transferOwnership(address)" 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:
- `target`: [0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4](https://github.com/ethereum-optimism/superchain-registry/blob/a9b57281842bf5742cf9e69114c6b81c622ca186/superchain/configs/mainnet/unichain.toml#L60C17-L60C59)
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4,false,0,0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a00000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](TODO: add governance post link here if this is going to be a governance proposal) section of the Governance proposal.

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
  
### [`0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`](https://github.com/ethereum-optimism/superchain-registry/blob/a9b57281842bf5742cf9e69114c6b81c622ca186/superchain/configs/mainnet/unichain.toml#L60C17-L60C59) (ProxyAdmin) - Chain ID: 130
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x6d5B183F538ABB8572F5cD17109c617b994D5833`
  - **After:** `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
  - **Summary:** Transferred ownership to the 2-of-2 multisig `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
    
  ---
  
### [`0x6d5b183f538abb8572f5cd17109c617b994d5833`](https://github.com/ethereum-optimism/superchain-registry/blob/a9b57281842bf5742cf9e69114c6b81c622ca186/superchain/configs/mainnet/unichain.toml#L45) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 130
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `5`
  - **After:** `6`
  - **Summary:** nonce incremented from 5 to 6
