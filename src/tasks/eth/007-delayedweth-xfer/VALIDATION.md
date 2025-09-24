# Validation

This document can be used to validate the inputs and result of the execution of the upgrade
transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the below hashes match what is on your ledger.
> ### Optimism Foundation Operations Safe
  Domain Hash:     0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890
  Message Hash:    0xb8b13da617762a29a6ca91db63ff91252839fdf80838f90932031378427c965c

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

# State Changes

## Single Safe State Overrides and Changes

This task is executed by the single Foundation Operations Safe. Refer to the
[generic single Safe execution validation document](../../../../../SINGLE-VALIDATION.md)
for the expected state overrides and changes.

Additionally, Safe-related nonces [will increment by one](../../../../../SINGLE-VALIDATION.md#nonce-increments).

## State Diffs

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

  ---
  
### `0x21429af66058bc3e4ae4a8f2ec4531aac433ecbc`  (DelayedWETH for PermissionedDisputeGame)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a`
  - **After:** `0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **Summary:** Owner of the DelayedWETH contract for the PermissionedDisputeGame transferred to the ProxyAdmin owner.
  - **Detail:** Address of the ProxyAdmin owner can be verified in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/b3d020de42abeebeb5786ea5508aa08d12bdf4cd/superchain/configs/mainnet/op.toml#L45).

Address of the `DelayedWETH` contract can be verified by pulling it from the
[PermissionedDisputeGame for OP Mainnet](https://github.com/ethereum-optimism/superchain-registry/blob/0831c2509152b457d865634616925ca6240b219e/superchain/configs/mainnet/op.toml#L66).
Using `cast` run:

```sh
cast call 0x1Ae178eBFEECd51709432EA5f37845Da0414EdFe "weth()(address)"
```

  ---

### `0x323dfc63c9b83cb83f40325aab74b245937cbdf0`  (DelayedWETH for FaultDisputeGame) - Chain ID: 10
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:**      `address`
  - **Before:** `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`
  - **After:** `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
  - **Summary:**           _owner
  - **Detail:** Address of the ProxyAdmin owner can be verified in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/b3d020de42abeebeb5786ea5508aa08d12bdf4cd/superchain/configs/mainnet/op.toml#L45).

Address of the `DelayedWETH` contract can be verified by pulling it from the
[FaultDisputeGame for OP Mainnet](https://github.com/ethereum-optimism/superchain-registry/blob/0831c2509152b457d865634616925ca6240b219e/superchain/configs/mainnet/op.toml#L64).
Using `cast` run:

```sh
cast call 0x5738a876359b48A65d35482C93B43e2c1147B32B "weth()(address)"
```

  ---
  
### `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`  (Foundation Operations Safe) - Chain ID: 10
  
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `103`
  - **After:** `104`
  - **Summary:** nonce
  - **Detail:** Nonce for the Foundation Operations Safe is bumped to 103
