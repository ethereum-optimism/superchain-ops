# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#state-validation)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.

> ### Unichain Upgrade Safe (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`)
>
> - Domain Hash:  `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0x393727497cdd4c2a8f2a198643b44956ce007757d0400d6d977191318d06aea8`
>
>
> ### Optimism Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x5a5cc02357b2f7a6836b2921063b549f077410c3d423d972c0029512f400a3c3`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: ``
> - Message Hash: ``

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x5a3f19f595ad7baf0483c96aa23a6bfe7c74b64eb5333a069650017ae4faa790`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM updatePrestate() function.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.updatePrestate()`

For each chain being updated, the `opcm.updatePrestate()` function is called with a tuple of three elements:

Unichain Mainnet:
  - SystemConfigProxy: [0xc407398d063f942feBbcC6F80a156b47F3f1BDA6](https://github.com/ethereum-optimism/superchain-registry/blob/9aabb8ab458b7e81c12b0cb919354f6b7dd4dc86/superchain/configs/mainnet/unichain.toml#L59)
  - ProxyAdmin: [0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4](https://github.com/ethereum-optimism/superchain-registry/blob/9aabb8ab458b7e81c12b0cb919354f6b7dd4dc86/superchain/configs/mainnet/unichain.toml#L60)
  - AbsolutePrestate: [0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6](https://www.notion.so/oplabs/Isthmus-Sepolia-Mainnet-1d2f153ee162800880abe1b47910c071)


Thus, the command to encode the calldata is:

```sh
UNI_SC=0xc407398d063f942feBbcC6F80a156b47F3f1BDA6
UNI_PA=0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4
PRESTATE=0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6
CALLDATA=$(cast calldata "updatePrestate((address,address,bytes32)[])" "[($UNI_SC,$UNI_PA,$PRESTATE)]")
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0x3a1f523a4bc09cd344a2745a108bb0398288094f](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L22) - Mainnet OPContractsManager 1.9.0 (op-contracts v3.0.0)
- `allowFailure`: false
- `callData`: `$CALLDATA` (result from the previous section)

Command to encode:
```sh
OPCM=0x3a1f523a4bc09cd344a2745a108bb0398288094f
cast calldata 'aggregate3((address,bool,bytes)[])' "[($OPCM,false,$CALLDATA)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003a1f523a4bc09cd344a2745a108bb0398288094f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a49a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000000000000000000000000000000000000
```

This calldata appears in the **Action Plan** section of the [Maintenance Governance Proposal](TODO) which is a follow up to authorize the actual Mainnet Superchain upgrade transactions for the [Upgrade 15](https://gov.optimism.io/t/upgrade-proposal-15-isthmus-hard-fork/9804) proposal.

## State Validation

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### Generic Safe State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

---

### `0xe5965ab5962edc7477c8520243a95517cd252fa9`  (DisputeGameFactory) - Chain ID: 10

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x0000000000000000000000001ae178ebfeecd51709432ea5f37845da0414edfe`
  - **After:**     `0x000000000000000000000000a1e0bacde89d899b3f24eef3d179cc335a24e777`
  - **Summary:**  Set a new game implementation for game type [PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55)
  - **Detail:**  This is `gameImpls[1]` -> `0xa1e0bacde89d899b3f24eef3d179cc335a24e777`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x0000000000000000000000005738a876359b48a65d35482c93b43e2c1147b32b`
  - **After:**     `0x00000000000000000000000089d68b1d63aaa0db4af1163e81f56b76934292f8`
  - **Summary:**  Set a new game implementation for game type [CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)
  - **Detail:**  This is `gameImpls[0]` -> `0x89d68b1d63aaa0db4af1163e81f56b76934292f8`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```
---

### [`0x24424336F04440b1c28685a38303aC33C9D14a25`](https://github.com/ethereum-optimism/superchain-ops/blob/2b33763cbae24bf5af1467f510e66a31b1b98b4a/NESTED-VALIDATION.md?plain=1#L106) (LivenessGuard)

> [!IMPORTANT]
> Security Council Only

**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

- **Key:**      `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:**  `0x00000000000000000000000000000000000000000000000000000000680a79a5`
  - **Summary:**  LivenessGuard timestamp update.
  - **Detail:**  **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**
                   When the security council safe executes a transaction, the liveness timestamps are updated.
                   This is updating at the moment when the  transaction is submitted (`block.timestamp`) into the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol#L41) mapping located at the slot 0.
---

### `0x6d5B183F538ABB8572F5cD17109c617b994D5833` (Unichain ProxyAdminOwner)

- Nonce increments see [below](#nonce-increments)
- `approvedHashes` mapping updates are explained in detail in [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md#key-computation).
  The key computations are:
  - **Unichain Safe only**
    ```
    SAFE_SIGNER=0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC
    SAFE_HASH=0x1ddd958de5bc75389847abb6cd0d8551f0ecfdaf763b9c80e935dbb1c37a3948
    cast index bytes32 $SAFE_HASH $(cast index address $SAFE_SIGNER 8)
    ```
  - **Optimism Foundation only**
    ```
    SAFE_SIGNER=0x847B5c174615B1B7fDF770882256e2D3E95b9D92
    SAFE_HASH=0x1ddd958de5bc75389847abb6cd0d8551f0ecfdaf763b9c80e935dbb1c37a3948
    cast index bytes32 $SAFE_HASH $(cast index address $SAFE_SIGNER 8)
    ```
  - **Security Council only**
    ```
    SAFE_SIGNER=0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
    SAFE_HASH=0x1ddd958de5bc75389847abb6cd0d8551f0ecfdaf763b9c80e935dbb1c37a3948
    cast index bytes32 $SAFE_HASH $(cast index address $SAFE_SIGNER 8)
    ```

---

### Nonce increments

- Contract deployments are shown as nonce increments from 0 to 1
  - `0x3cCF7C31a3A8C1b8aaA9A18FC2d010dDE4262342` - Permissionless GameType Implementation for Ink
  - `0x40641A4023f0F4C66D7f8Ade16497f4C947A7163` - Permissioned GameType Implementation for Ink
  - `0x89D68b1D63AAA0db4af1163e81f56B76934292F8` - Permissionless GameType Implementation for OP Mainnet
  - `0xa1E0baCde89d899B3f24eEF3D179cC335A24E777` - Permissioned GameType Implementation for OP Mainnet
- The remaining nonce increments are for the Safes and EOAs that are involved in the simulation.
  The details are described in the generic [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) document.
  - <sender-address> - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe (if you're simulating)).
  - `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` - Superchain ProxyAdminOwner
    - Contract nonce `14 -> 18` - four contract deployments above
    - Safe nonce (slot `0x5`) `14 -> 15`
  - `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` - Foundation Upgrade Safe `25 -> 26`
  - `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` - Security Council Safe `26 -> 27`
