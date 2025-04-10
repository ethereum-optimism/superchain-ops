# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xcac3a791b4b20b7253bb689e577742d70d3a12e36bce4ef472beee34eddb323f`
>
> ### Optimism Foundation
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x36477217cdf193cfa0791b50b4b08339df0b40ff9935fdfbb3380c033e9cafef`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v3.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. OP Sepolia Testnet:
  - SystemConfigProxy: [0x034edD2A225f7f429A63E0f1D2084B9E0A93b538](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/op.toml#L58)
  - ProxyAdmin: [0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/op.toml#L59)
  - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-prestates.toml#L10)

2. Soneium Testnet Minato:
  - SystemConfigProxy: [0x4Ca9608Fef202216bc21D543798ec854539bAAd3](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/soneium-minato.toml#L59)
  - ProxyAdmin: [0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/soneium-minato.toml#L60)
  - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-prestates.toml#L10)

3. Ink Sepolia:
  - SystemConfigProxy: [0x05C993e60179f28bF649a2Bb5b00b5F4283bD525](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/ink.toml#L58)
  - ProxyAdmin: [0xd7dB319a49362b2328cf417a934300cCcB442C8d](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/ink.toml#L59)
  - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-prestates.toml#L10)


Thus, the command to encode the calldata is:


```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538,0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc,0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405),(0x4Ca9608Fef202216bc21D543798ec854539bAAd3,0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0,0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405),(0x05C993e60179f28bF649a2Bb5b00b5F4283bD525,0xd7dB319a49362b2328cf417a934300cCcB442C8d,0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0xfbceed4de885645fbded164910e10f52febfab35](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L22) - Sepolia OPContractsManager v3.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xfbceed4de885645fbded164910e10f52febfab35,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee4050000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db003ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fbceed4de885645fbded164910e10f52febfab35000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000164ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee4050000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db003ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-14-isthmus-l1-contracts-mt-cannon/9796#p-43948-action-plan-9) section of the Governance proposal.

# State Changes

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping of the `ProxyAdminOwner` should change during the simulation.
See the ["Key Computation" section](../../../../../NESTED-VALIDATION.md#key-computation) in the nested validation doc
for instruction on how to validate this change.  You can find the target safe hash in the simulation output
under "Nested Multisig Child's Hash to Approve", which should be:
- `0x7ae8800316ad25e257c77b54d034e5befc61dc38da97801125cc99f404be529e`

Additionally, Safe-related nonces [will increment by one](../../../../../NESTED-VALIDATION.md#nonce-increments).

## Other Nonces
In addition to the Safe-related nonces mentioned [previously](#nested-safe-state-overrides-and-changes),
new contracts will also have a nonce value increment from 0 to 1.
This due to [EIP-161](https://eips.ethereum.org/EIPS/eip-161) which activated in 2016.

This affects the newly deployed dispute games mentioned in ["State Diffs"](#state-diffs).

## State Diffs

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### [`0x034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/sepolia/op.toml#L59) (SystemConfig) Chain ID: 11155420

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L9)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard. SystemConfig contract for `op-contracts/v3.0.0-rc.2`.

  ---

### [`0x05c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L59-L59) (SystemConfig) - Chain ID: 763373

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** `[0x340f923E5c7cbB2171146f64169EC9d5a9FfE647](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L9-L9)`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard. SystemConfig contract for `op-contracts/v3.0.0-rc.2`.

  ---

### [`0x05f9613adb30026ffd634f38e5c4dfd30a197fa1`]((https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/op.toml#L63-L63)) (DisputeGameFactory) - Chain ID: 11155420

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x0000000000000000000000007717296cac5d39d362eb77a94c95483bebae214e`
  - **After:**     `0x000000000000000000000000845e5382d60ec16e538051e1876a985c5339cc62`
  - **Summary:** Set a new game implementation for game type [PERMISSIONED_CANNON.](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55")
    - **Detail:** You can verify this slot corresponds to the game implementation for game type 1 by 
                      deriving the slot value as follows:
                      - Notice that [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57") is a map from a `GameType` to a dispute game address.
                      - Notice that `GameType` is [equivalent to a]("https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224").
                      - Notice that the `gameImpls` [stored at slot 101]("https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41"). 
                      - Calculate the expected slot for game type 1 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                        - `cast index uint32 1 101`
                      - You should derive a value matching the "Raw Slot" here: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f   

  - **Summary:**  Set a new game implementation for game type [CANNON]("https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52")
  - **Detail:** You can verify this slot corresponds to the game implementation for game type 0 by 
                     deriving the slot value as follows:
                     - Notice that [`gameImpls`]("https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57") is a map from a `GameType` to a dispute game address</a>.
                     - Notice that `GameType` is [equivalent to a ]("https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224") `uint32`.                      
                     - Notice that the `gameImpls` is [stored at slot 101]("https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41"). 
                     - Calculate the expected slot for game type 0 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                       - `cast index uint32 0 101`
                     - You should derive a value matching the "Raw Slot" here: 0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b 

  ---

### [`0x16fc5058f25648194471939df75cf27a2fdc48bc`](https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/op.toml#L58)  (OptimismPortal2) - Chain ID: 11155420

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** `[0xB443Da3e07052204A02d630a8933dAc05a0d6fB4](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L13-L13)`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0x1eb2ffc903729a0f03966b917003800b145f56e2`](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-config-roles-sepolia.toml#L3)  (ProxyAdminOwner (GnosisSafe)) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `26`
  - **After:** `27`
  - **Summary:**           nonce
  - **Detail:**

  ---

### [`0x2bfb22cd534a462028771a1ca9d6240166e450c4`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L55-L55)  (L1ERC721Bridge - Soneium Testnet Minato) - Chain ID: 1946

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L19-L19)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0x33f60714bbd74d62b66d79213c348614de51901c`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L56-L5)  (L1StandardBridge) - Chain ID: 763373

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L20-L20)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0x3454f9df5e750f1383e58c1cb001401e7a4f3197`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L53-L53)  (AddressManager) - Chain ID: 763373

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:**     `0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **Summary:**  The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v3.0.0-rc.2' L1CrossDomainMessenger at [0x5d5a095665886119693f0b41d8dfee78da033e8b](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L18).
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    This key is complicated to compute, so instead we attest to correctness of the key by
    verifying that the "Before" value currently exists in that slot, as explained below.
    **Before** address matches the following cast call to `AddressManager.getAddress()`:
      - `cast call 0x3454F9df5E750F1383e58c1CB001401e7A4f3197 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia`
      - returns: `0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231`

  ---

### [`0x4ca9608fef202216bc21d543798ec854539baad3`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L60-L60)  (SystemConfig) - Chain ID: 1946

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L9-L9)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0x5c1d29c6c9c8b0800692acc95d700bcb4966a1d7`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L58-L58)  (OptimismPortal2) - Chain ID: 763373

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** [`0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L13-L13)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0x5f5a404a5edabcdd80db05e8e54a78c9ebf000c2`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L56-L56) (L1StandardBridg - Soneium Testnet Minato) - Chain ID: 1946

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L20-L20)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0x65ea1489741a5d72ffdd8e6485b216bbdcc15af3`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L59-L59)  (OptimismPortal2) - Chain ID: 1946

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** [`0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L13-L13)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0x6e8a77673109783001150dfa770e6c662f473da9`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L53-L53)  (AddressManager - Soneium Testnet Minato) - Chain ID: 1946

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:**     `0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **Summary:**   The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v3.0.0-rc.2' L1CrossDomainMessenger at [0x5d5a095665886119693f0b41d8dfee78da033e8b](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L18).
  - **Detail:**   This key is complicated to compute, so instead we attest to correctness of the key by
                     verifying that the "Before" value currently exists in that slot, as explained below.
                     **Before** address matches both of the following cast calls:
                      1. What is returned by calling `AddressManager.getAddress()`:
                       -  `cast call 0x6e8A77673109783001150DFA770E6c662f473DA9 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia`
                      2. What is currently stored at the key:
                       - `cast storage 0x6e8A77673109783001150DFA770E6c662f473DA9 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url sepolia`

  ---

### [`0x860e626c700af381133d9f4af31412a2d1db3d5d`](https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/ink.toml#L64)  (DisputeGameFactory) - Chain ID: 763373

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x00000000000000000000000065e5ec10f922cf7e61ead974525a2795bd4fda9a`
  - **After:**     `0x000000000000000000000000de2b69153c42191eb4863a36024d80a1d426d0c8`
- **Summary:** Set a new game implementation for game type (1 PERMISSIONED_CANNON)[https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55">].
  - **Detail:**      You can verify this slot corresponds to the game implementation for game type 1 by 
                     deriving the slot value as follows:
                     - Notice that [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57") is a map from a `GameType` to a dispute game address</a>.
                     - Notice that `GameType` is [equivalent to](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224) a `uint32`</a>.
                     - Notice that the `gameImpls` is [stored at slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41). 
                     - Calculate the expected slot for game type 1 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                       - `cast index uint32 1 101`
                     - You should derive a value matching the "Raw Slot" here: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x00000000000000000000000043736de4bd35482d828b79ea673b76ab1699626f`
  - **After:**     `0x0000000000000000000000000c356f533eb009deb302bc96522e80dea6a16276`
  - **Summary:**   Set a new game implementation for game type [0 CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52").
    - **Detail:**  You can verify this slot corresponds to the game implementation for game type 0 by 
                      deriving the slot value as follows:
                      - Notice that [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is a map from a `GameType` to a dispute game address</a>.
                      - Notice that `GameType` is [equivalent to a](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224) `uint32`</a>.                      - Notice that the `gameImpls` is [stored at slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41). 
                      - Calculate the expected slot for game type 0 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                        - `cast index uint32 0 101`
                      - You should derive a value matching the "Raw Slot" here: 0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b

  ---

### [`0x9bfe9c5609311df1c011c47642253b78a4f33f4b`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/op.toml#L53-L53)  (AddressManager) - Chain ID: 11155420

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:**     `0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **Summary:**  The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v3.0.0-rc.2' L1CrossDomainMessenger at [0x5d5a095665886119693f0b41d8dfee78da033e8b](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L18)
    - **Detail:**  This key is complicated to compute, so instead we attest to correctness of the key by
                      verifying that the "Before" value currently exists in that slot, as explained below.
                      **Before** address matches both of the following cast calls:
                        1. What is returned by calling `AddressManager.getAddress()`:
                        - `cast call 0x9bFE9c5609311DF1c011c47642253B78a4f33F4B 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia`
                        2. What is currently stored at the key:
                        - `cast storage 0x9bFE9c5609311DF1c011c47642253B78a4f33F4B 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url sepolia`

  ---

### [`0xb3ad2c38e6e0640d7ce6aa952ab3a60e81bf7a01`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L64)  (DisputeGameFactory - - Soneium Testnet Minato) - Chain ID: 1946

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x0000000000000000000000002087cbc6ec893a31405d56025cd1ae648da3982c`
  - **After:**     `0x000000000000000000000000697a4684576d8a76d4b11e83e9b6f3b61bf04755`
  - **Summary:**  Set a new game implementation for game type [1 (PERMISSIONED_CANNON)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55).
    - **Detail:** You can verify this slot corresponds to the game implementation for game type 1 by 
                      deriving the slot value as follows:
                      - Notice that [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is a map from a `GameType` to a dispute game address</a>.
                      - Notice that `GameType` is [equivalent to a](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224) `uint32`.
                      - Notice that the `gameImpls` is [stored at slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41)
                      - Calculate the expected slot for game type 1 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                        - `cast index uint32 1 101`
                      - You should derive a value matching the "Raw Slot" here: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e

  ---

### [`0xd1c901bbd7796546a7ba2492e0e199911fae68c7`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L55-L55)  (L1ERC721Bridge) - Chain ID: 763373

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L19-L19)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0xd83e03d576d23c9aeab8cc44fa98d058d2176d1f`](https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/op.toml#L55)  (L1ERC721Bridge) - Chain ID: 11155420

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L19-L19)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0xfbb0621e0b23b5478b630bd55a5f21f67730b0f1`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/op.toml#L56-L56)  (L1StandardBridge) - Chain ID: 11155420

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L20-L20)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### [`0xfbceed4de885645fbded164910e10f52febfab35`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L22-L22) (OPCM) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:**     `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:**     `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:**  **IMPORTANT: THIS STATE CHANGE MAY NOT APPEAR IN THE TENDERLY STATE DIFF.**
                      `isRC` storage slot updated to 0.
    - **Detail:**  Once OPContractsManager is upgraded, the `isRC` flag is set to false.
                      This happens in the first invocation of the `upgrade` function.
                      Slot 22 is the `isRC` flag: `cast to-hex 22` -> `0x16`.
                      Please refer to `'Figure 0.1'` at the end of this report for the storage layout of OPContractsManager.
  ---
  
# Supplementary Material

## Figure 0.1: Storage Layout of OPContractsManager

![OPContractsManager isRC flag set to false](./images/op-contracts-manager-storage-layout.png)
