# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. Validate the Domain and Message Hashes
2. Verifying the state changes via the normalized state diff hash
3. Verifying the transaction input
4. Verifying the state changes

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
> - Message Hash: `0x393727497cdd4c2a8f2a198643b44956ce007757d0400d6d977191318d06aea8`
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

This document provides a detailed analysis of the final calldata executed on-chain. By reconstructing the calldata and simulating it, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

The calldata provided in the [governance proposal](https://gov.optimism.io/t/upgrade-proposal-15a-absolute-prestate-updates-for-isthmus-activation-blob-preimage-fix/9869#p-44190-action-plan-10) for Unichain is:

```sh
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003a1f523a4bc09cd344a2745a108bb0398288094f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a49a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000000000000000000000000000000000000
```

### Inputs to `Multicall3.aggregate3()`

The calldata from the governance proposal is the arguments to the `aggregate3()` function of the `Multicall3` contract, at [`0xca11bde05977b3631167028862be2a173976ca11`](https://etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11).

The command to decode the calldata is:

```sh
cast decode-calldata "aggregate3((address,bool,bytes)[])" 0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003a1f523a4bc09cd344a2745a108bb0398288094f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a49a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000000000000000000000000000000000000
```

The decoded arguments is an array with a single tuple of three elements:

```
[(
0x3A1f523a4bc09cd344A2745a108Bb0398288094F,
false,
0x9a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6
)]
```

This tuple is the `Call3` struct, which represents the parameters for a single call:

- `target`: The `OPContractsManager` contract
- `allowFailure`: `false`
- `calldata`: As shown above

### Inputs to `OPContractsManager.updatePrestate()`

The calldata in the `Call3` struct above is the arguments to the `updatePrestate()` function of the `OPContractsManager` contract, at [`0x3A1f523a4bc09cd344A2745a108Bb0398288094F`](https://etherscan.io/address/0x3A1f523a4bc09cd344A2745a108Bb0398288094F).

The command to decode the calldata is:

```sh
cast decode-calldata "updatePrestate((address,address,bytes32)[])" 0x9a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6
```

The decoded arguments is an array with a single tuple of three elements:

```
[
    (
        0xc407398d063f942feBbcC6F80a156b47F3f1BDA6,
        0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4,
        0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6
    )
]
```

This tuple is an `OpChainConfig` struct for the chain being updated, which is Unichain:

- `systemConfigProxy`: [`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`](https://etherscan.io/address/0xc407398d063f942feBbcC6F80a156b47F3f1BDA6)
- `proxyAdmin`: [`0x543bA4AADBAb8f9025686Bd03993043599c6fB044`](https://etherscan.io/address/0x543bA4AADBAb8f9025686Bd03993043599c6fB044)
- `absolutePrestate`: `0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6`

As a result, `OPContractsManager.updatePrestate()` is called to update the prestate hash for Unichain mainnet.

## State Validation

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### Generic Safe State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](https://github.com/ethereum-optimism/superchain-ops/blob/seb/eth-007-opcm-update-prestate-op%2Bink/NESTED-VALIDATION.md) file.

---


### `0x2f12d621a16e2d3285929c9996f478508951dfe4`  (DisputeGameFactory) - Chain ID: 130 (UNICHAIN)
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x00000000000000000000000067d59ac1166ba17612be0edf275187e38cbf9b99`
  - **After:**     `0x000000000000000000000000485272c0703020e1354328a1aba3ca767997bed3`
  - **Summary:**     Replaces Dispute Game Implementation in the `DisputeGameFactory` contract
    - **Detail:**      This state update will replace the old Dispute Game implementation for the Game Type 1 ([PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55)) - [0x67d59ac1166ba17612be0edf275187e38cbf9b99](https://etherscan.io/address/0x67d59ac1166ba17612be0edf275187e38cbf9b99) (old) => `0x485272c0703020e1354328a1aba3ca767997bed3` (new)
  - **Key Explanation:** The key represents the position in the [gameImpls mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) of the targeted Game Type
  
  If we run the following command it will give us the exact position of Game Type 1 (PERMISSIONED_CANNON) `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`:
  ```shell
  cast index uint32 1 101
  ```
  GameType is **uint32** type

  Position in the mapping is **1**

  Slot in the contract's storage is **101**
  #### Note: The new game implementation is identical to the old one, with the only update being the prestate set to `0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6`.
  

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x00000000000000000000000056ebb9eae4f33ceaed3672446e3812d77f8a8a2c`
  - **After:**     `0x00000000000000000000000057a3b42698dc1e4fb905c9ab970154e178296991`
  - **Summary:**     Replaces Dispute Game Implementation in the `DisputeGameFactory` contract
  - **Detail:**      This state update will replace the old Dispute Game implementation for the Game Type 0 ([CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)) - [0x56ebb9eae4f33ceaed3672446e3812d77f8a8a2c](https://etherscan.io/address/0x56ebb9eae4f33ceaed3672446e3812d77f8a8a2c) (old) => `0x57a3b42698dc1e4fb905c9ab970154e178296991` (new)
  - **Key Explanation:** The key represents the position in the [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) of the targeted Game Type
  
  If we run the following command it will give us the exact position of Game Type 0 (CANNON) `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`:
  ```shell
  cast index uint32 0 101
  ```
  GameType is **uint32** type

  Position in the mapping is **0**

  Slot in the contract's storage is **101**
  #### Note: The new game implementation is identical to the old one, with the only update being the prestate set to `0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6`.
---
### [0x9343c452dec3251fe99D9Fd29b74c5b9CD1751a6](http://github.com/ethereum-optimism/superchain-ops/blob/2b33763cbae24bf5af1467f510e66a31b1b98b4a/NESTED-VALIDATION.md?plain=1#L107) (LivenessGuard Unichain)

> [!IMPORTANT]
> Unichain Safe Only

**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE UNICHAIN SAFE AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

The details are explained in [NESTED-VALIDATION.md](http://github.com/ethereum-optimism/superchain-ops/blob/2b33763cbae24bf5af1467f510e66a31b1b98b4a/NESTED-VALIDATION.md#liveness-guard).

---

### [0x24424336F04440b1c28685a38303aC33C9D14a25](http://github.com/ethereum-optimism/superchain-ops/blob/2b33763cbae24bf5af1467f510e66a31b1b98b4a/NESTED-VALIDATION.md?plain=1#L106) (LivenessGuard Security Council)

> [!IMPORTANT]
> Security Council Only

**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

The details are explained in [NESTED-VALIDATION.md](http://github.com/ethereum-optimism/superchain-ops/blob/2b33763cbae24bf5af1467f510e66a31b1b98b4a/NESTED-VALIDATION.md#liveness-guard).

---

### `0x6d5b183f538abb8572f5cd17109c617b994d5833` (Unichain ProxyAdminOwner)

- Nonce increments see below
- `approvedHashes` mapping updates are explained in detail in [NESTED-VALIDATION.md](https://github.com/ethereum-optimism/superchain-ops/blob/seb/eth-007-opcm-update-prestate-op%2Bink/NESTED-VALIDATION.md#key-computation).
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
  - `0x485272c0703020e1354328A1aBa3ca767997BEd3` - Permissioned [PERMISSIONED_CANNON] GameType Implementation for Unichain Mainnet
  - `0x57a3B42698DC1e4Fb905c9ab970154e178296991` - Permissionless [CANON] GameType Implementation for Unichain Mainnet
- The remaining nonce increments are for the Safes and EOAs that are involved in the simulation.
  The details are described in the generic [NESTED-VALIDATION.md](https://github.com/ethereum-optimism/superchain-ops/blob/seb/eth-007-opcm-update-prestate-op%2Bink/NESTED-VALIDATION.md) document.
  - <sender-address> - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe (if you're simulating)).
  - `0x6d5B183F538ABB8572F5cD17109c617b994D5833` - Unichain ProxyAdminOwner
    - Contract nonce `6 -> 8` - two contract deployments above
    - Safe nonce (slot `0x5`) `4 -> 5`
  - Only one of the following nonce increments, depending on which Owner Safe is simulated
    - `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC` - Unichain Operations Safe `10 -> 11`
    - `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` - Foundation Upgrade Safe `25 -> 26`
    - `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` - Security Council Safe `26 -> 27`

### Suplement Material
The following is the storage slots layout of the `DisputeGameFactory` contract:

![Unknown 135.png](https://imagedelivery.net/wtv4_V7VzVsxpAFaxzmpbw/4635bf65-1f05-4d09-446c-e2fca1ea8a00/public)  



## Delivered by Spearbit on 01/05/2025 
https://cantina.xyz/portfolio/284b7d84-cb79-4cc2-bd49-6b2434ea1b61