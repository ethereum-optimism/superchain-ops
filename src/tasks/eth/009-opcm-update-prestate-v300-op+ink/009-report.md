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
> ### Optimism Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xe742f60fe2e614478b475c5da80c7898f5e09668d158beb37d5131eeb34108f4`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xe8dfdb92b25d01287028007b3c52a3a8b52a7204c6e8a2ebd7455ac8e7246a5f`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x4d50717185117827e3265c4183bfad6a0e839821a189342d38134f2e63a9c3b1`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain. By reconstructing the calldata and simulating it, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

The calldata provided in the [governance proposal](https://gov.optimism.io/t/upgrade-proposal-15a-absolute-prestate-updates-for-isthmus-activation-blob-preimage-fix/9869#p-44190-action-plan-10) is:

```sh
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003a1f523a4bc09cd344a2745a108bb0398288094f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001049a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000000000000000000000000000000000000
```

### Inputs to `Multicall3Delegatecall.aggregate3()`

The calldata from the governance proposal is the arguments to the `aggregate3()` function of the `Multicall3Delegatecall` contract, at [`0x93dc480940585d9961bfceab58124ffd3d60f76a`](https://etherscan.io/address/0x93dc480940585d9961bfceab58124ffd3d60f76a).

The command to decode the calldata is:

```sh
cast decode-calldata "aggregate3((address,bool,bytes)[])" 0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003a1f523a4bc09cd344a2745a108bb0398288094f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001049a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000000000000000000000000000000000000
```

The decoded arguments is an array with a single tuple of three elements:

```
[(
0x3A1f523a4bc09cd344A2745a108Bb0398288094F, 
false
0x9a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6
)]
```

This tuple is the `Call3` struct, which represents the parameters for a single delegatecall:

- `target`: The `OPContractsManager` contract
- `allowFailure`: `false`
- `calldata`: As shown above

### Inputs to `OPContractsManager.updatePrestate()`

The calldata in the `Call3` struct above is the arguments to the `updatePrestate()` function of the `OPContractsManager` contract, at [`0x3A1f523a4bc09cd344A2745a108Bb0398288094F`](https://etherscan.io/address/0x3A1f523a4bc09cd344A2745a108Bb0398288094F).

THe command to decode the calldata is:

```sh
cast decode-calldata "updatePrestate((address,address,bytes32)[])" 0x9a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6
```

The decoded arguments is an array of tuples with three elements:

```
[
    (
        0x229047fed2591dbec1eF1118d64F7aF3dB9EB290, 
        0x543bA4AADBAb8f9025686Bd03993043599c6fB04,
        0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6
    ), 
    (
        0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,
        0xd56045E68956FCe2576E680c95a4750cf8241f79,
        0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6
    )
]
```

Each tuple is an `OpChainConfig` struct for each chain being updated:

1. OP Mainnet:
   - `systemConfigProxy`: [`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://etherscan.io/address/0x229047fed2591dbec1eF1118d64F7aF3dB9EB290)
   - `proxyAdmin`: [`0x543bA4AADBAb8f9025686Bd03993043599c6fB04`](https://etherscan.io/address/0x543bA4AADBAb8f9025686Bd03993043599c6fB04)
   - `absolutePrestate`: `0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6`
2. Ink Mainnet:
   - `systemConfigProxy`: [`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364)
   - `proxyAdmin`: [`0xd56045E68956FCe2576E680c95a4750cf8241f79`](https://etherscan.io/address/0xd56045E68956FCe2576E680c95a4750cf8241f79)
   - `absolutePrestate`: `0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6`

As a result, `OPContractsManager.updatePrestate()` is called to update the prestate hash for both OP and Ink mainnet.

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


### `0x10d7b35078d3baabb96dd45a9143b94be65b12cd`  (DisputeGameFactory) - Chain ID: 57073 (INK)
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x000000000000000000000000436bac2efe273e3f13eefeda2b3689c34591bca1`
  - **After:**     `0x00000000000000000000000040641a4023f0f4c66d7f8ade16497f4c947a7163`
  - **Summary:**     Replaces Dispute Game Implementation in the `DisputeGameFactory` contract
  - **Detail:**      This state update will replace the old Dispute Game implementation for the Game Type 1 ([PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55)) - [0x436bac2efe273e3f13eefeda2b3689c34591bca1](https://etherscan.io/address/0x436bac2efe273e3f13eefeda2b3689c34591bca1) (old) => `0x40641a4023f0f4c66d7f8ade16497f4c947a7163` (new)
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
  - **Before:**     `0x000000000000000000000000499e30a3b1bdb03f554ffffae4c9c5edf31ca554`
  - **After:**     `0x0000000000000000000000003ccf7c31a3a8c1b8aaa9a18fc2d010dde4262342`
  - **Summary:**     Replaces Dispute Game Implementation in the `DisputeGameFactory` contract
  - **Detail:**      This state update will replace the old Dispute Game implementation for the Game Type 0 ([CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)) - [0x499e30a3b1bdb03f554ffffae4c9c5edf31ca554](https://etherscan.io/address/0x499e30a3b1bdb03f554ffffae4c9c5edf31ca554) (old) => `0x3ccf7c31a3a8c1b8aaa9a18fc2d010dde4262342` (new)
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
  
### `0xe5965ab5962edc7477c8520243a95517cd252fa9`  (DisputeGameFactory) - Chain ID: 10 (Optimism Mainnet)
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x0000000000000000000000001ae178ebfeecd51709432ea5f37845da0414edfe`
  - **After:**     `0x000000000000000000000000a1e0bacde89d899b3f24eef3d179cc335a24e777`
  - **Summary:**     Replaces Dispute Game Implementation in the `DisputeGameFactory` contract
  - **Detail:**      This state update will replace the old Dispute Game implementation for the Game Type 1 ([PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55)) - [0x1ae178ebfeecd51709432ea5f37845da0414edfe](https://etherscan.io/address/0x1ae178ebfeecd51709432ea5f37845da0414edfe) (old) => `0xa1e0bacde89d899b3f24eef3d179cc335a24e777` (new)
  - **Key Explanation:** The key represents the position in the [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) of the targeted Game Type
  
  If we run the following command it will give us the exact position of Game Type 1 (PERMISSIONED_CANNON) `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`:
  ```shell
  cast index uint32 1 101
  ```
  GameType is **uint32** type

  Position in the mapping is **1**

  Slot in the contract's storage is **101**
  #### Note: The new game implementation is identical to the old one, with the only update being the prestate set to `0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6`.

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x0000000000000000000000005738a876359b48a65d35482c93b43e2c1147b32b`
  - **After:**     `0x00000000000000000000000089d68b1d63aaa0db4af1163e81f56b76934292f8`
  - **Summary:**     Replaces Dispute Game Implementation in the `DisputeGameFactory` contract
  - **Detail:**      This state update will replace the old Dispute Game implementation for the Game Type 0 ([CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)) - [0x5738a876359b48a65d35482c93b43e2c1147b32b](https://etherscan.io/address/0x5738a876359b48a65d35482c93b43e2c1147b32b) (old) => `0x89d68b1d63aaa0db4af1163e81f56b76934292f8` (new)
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

### [`0x24424336F04440b1c28685a38303aC33C9D14a25`](https://github.com/ethereum-optimism/superchain-ops/blob/2b33763cbae24bf5af1467f510e66a31b1b98b4a/NESTED-VALIDATION.md?plain=1#L106) (LivenessGuard)

> [!IMPORTANT]
> Security Council Only

**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

The details are explained in [NESTED-VALIDATION.md](https://github.com/ethereum-optimism/superchain-ops/blob/seb/eth-007-opcm-update-prestate-op%2Bink/NESTED-VALIDATION.md#liveness-guard).

---

### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (Superchain ProxyAdminOwner)

- Nonce increments see below
- `approvedHashes` mapping updates are explained in detail in [NESTED-VALIDATION.md](https://github.com/ethereum-optimism/superchain-ops/blob/seb/eth-007-opcm-update-prestate-op%2Bink/NESTED-VALIDATION.md#key-computation).
  The key computations are:
  - **Foundation only**
    ```
    SAFE_SIGNER=0x847B5c174615B1B7fDF770882256e2D3E95b9D92
    SAFE_HASH=0x410dacd36755998923076d5c5f115b77116f3e479a9a5cecf45f6c2dab3da479
    cast index bytes32 $SAFE_HASH $(cast index address $SAFE_SIGNER 8)
    ```
    Key: `0xea44a27dff7f1fec743500257a14e44c424876595dfb8c1eaf765eecdd3c4f41`
  - **Security Council only**
    ```
    SAFE_SIGNER=0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
    SAFE_HASH=0x410dacd36755998923076d5c5f115b77116f3e479a9a5cecf45f6c2dab3da479
    cast index bytes32 $SAFE_HASH $(cast index address $SAFE_SIGNER 8)
    ```
    Key: `0xb32ab0e2f892afb0356b7eb63cab3a3ba9ad4d3a01899d832360c55ddfa4a785`

---

### Nonce increments

- Contract deployments are shown as nonce increments from 0 to 1
  - `0x3cCF7C31a3A8C1b8aaA9A18FC2d010dDE4262342` - Permissionless [CANON] GameType Implementation for Ink
  - `0x40641A4023f0F4C66D7f8Ade16497f4C947A7163` - Permissioned [PERMISSIONED_CANNON] GameType Implementation for Ink
  - `0x89D68b1D63AAA0db4af1163e81f56B76934292F8` - Permissionless [CANON] GameType Implementation for OP Mainnet
  - `0xa1E0baCde89d899B3f24eEF3D179cC335A24E777` - Permissioned [PERMISSIONED_CANNON] GameType Implementation for OP Mainnet
- The remaining nonce increments are for the Safes and EOAs that are involved in the simulation.
  The details are described in the generic [NESTED-VALIDATION.md](https://github.com/ethereum-optimism/superchain-ops/blob/seb/eth-007-opcm-update-prestate-op%2Bink/NESTED-VALIDATION.md) document.
  - <sender-address> - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe (if you're simulating)).
  - `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` - Superchain ProxyAdminOwner
    - Contract nonce `14 -> 18` - four contract deployments above
    - Safe nonce (slot `0x5`) `14 -> 15`
  - Only one of the following nonce increments, depending on which Owner Safe is simulated
    - `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` - Foundation Upgrade Safe `24 -> 25`
    - `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` - Security Council Safe `25 -> 26`

### Suplement Material
The following is the storage slots layout of the DisputeGameFactory
  ![Unknown 135.png](https://imagedelivery.net/wtv4_V7VzVsxpAFaxzmpbw/4635bf65-1f05-4d09-446c-e2fca1ea8a00/public)  


## Delivered by Spearbit on 01/05/2025 
https://cantina.xyz/portfolio/284b7d84-cb79-4cc2-bd49-6b2434ea1b61