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

> ### Unichain Upgrade Safe (Chain Governor) (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`)
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
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xbfe796bd508232de1207a8668e26b13a3c4fdd8486b7b6a0636586bb045cb489`

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

### `0x2f12d621a16e2d3285929c9996f478508951dfe4`  (DisputeGameFactory) - Chain ID: 130

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x00000000000000000000000067d59ac1166ba17612be0edf275187e38cbf9b99`
  - **After:**     `0x000000000000000000000000485272c0703020e1354328a1aba3ca767997bed3`
  - **Summary:**  Set a new game implementation for game type [PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55)
  - **Detail:**  This is `gameImpls[1]` -> `0x485272c0703020e1354328A1aBa3ca767997BEd3`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x00000000000000000000000056ebb9eae4f33ceaed3672446e3812d77f8a8a2c`
  - **After:**     `0x00000000000000000000000057a3b42698dc1e4fb905c9ab970154e178296991`
  - **Summary:**  Set a new game implementation for game type [CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)
  - **Detail:**  This is `gameImpls[0]` -> `0x57a3B42698DC1e4Fb905c9ab970154e178296991`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```

---

### `0x9343c452dec3251fe99D9Fd29b74c5b9CD1751a6` (LivenessGuard Unichain)

> [!IMPORTANT]
> Unichain Safe Only

**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE UNICHAIN SAFE AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

The details are explained in [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md#liveness-guard).

---

### `0x24424336F04440b1c28685a38303aC33C9D14a25` (LivenessGuard Security Council)

> [!IMPORTANT]
> Security Council Only

**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

The details are explained in [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md#liveness-guard).

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
    Key: `0xf8504c099de345eb1c403a30d49833b4834f40d609b6b2107b81927e309b987a`
  - **Optimism Foundation only**
    ```
    SAFE_SIGNER=0x847B5c174615B1B7fDF770882256e2D3E95b9D92
    SAFE_HASH=0x1ddd958de5bc75389847abb6cd0d8551f0ecfdaf763b9c80e935dbb1c37a3948
    cast index bytes32 $SAFE_HASH $(cast index address $SAFE_SIGNER 8)
    ```
    Key: `0xab2f364801a9ab669e9ddf4ec9b8d06c52acca51c9626e5242dd8a9b79a1f0aa`
  - **Security Council only**
    ```
    SAFE_SIGNER=0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
    SAFE_HASH=0x1ddd958de5bc75389847abb6cd0d8551f0ecfdaf763b9c80e935dbb1c37a3948
    cast index bytes32 $SAFE_HASH $(cast index address $SAFE_SIGNER 8)
    ```
    Key: `0x488861e7a26dcec539aebd39e2015ecbaaa7c5924c668939a8cfe1af67718786`

---

### Nonce increments

- Contract deployments are shown as nonce increments from 0 to 1
  - `0x485272c0703020e1354328A1aBa3ca767997BEd3` - Permissioned GameType Implementation for Unichain Mainnet
  - `0x57a3B42698DC1e4Fb905c9ab970154e178296991` - Permissionless GameType Implementation for Unichain Mainnet
- The remaining nonce increments are for the Safes and EOAs that are involved in the simulation.
  The details are described in the generic [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) document.
  - <sender-address> - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe (if you're simulating)).
  - `0x6d5B183F538ABB8572F5cD17109c617b994D5833` - Unichain ProxyAdminOwner
    - Contract nonce `6 -> 8` - two contract deployments above
    - Safe nonce (slot `0x5`) `4 -> 5`
  - Only one of the following nonce increments, depending on which Owner Safe is simulated
    - `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC` - Unichain Operations Safe `10 -> 11`
    - `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` - Foundation Upgrade Safe `25 -> 26`
    - `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` - Security Council Safe `26 -> 27`
