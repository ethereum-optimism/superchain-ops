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
> - Message Hash: `0xcedbef00e8b71f0cc711f32fe6dd303bcd5430ca36bfb66c6197ad120e790cc3`
>
> ### Optimism Foundation
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x275f0430264902f68a30cd951573e874e52d34e969ce4b3e7a756eb6f38a11dd`

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

<!-- TODO(#740) - Add a link to the gov post -->
In mainnet runbooks, this calldata should appear in [Action Plan]() section of the Governance proposal.

# State Changes

## Nested Safe State Overrides and Changes

<!--TODO(#740) - I see additional overrides to the ProxyAdminSafe not documented in NESTED-VALIDATION.md -->
This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

<!--TODO(#740) - Figure out how to retrieve the $SAFE_HASH, I don't see it printed in the output -->
The `approvedHashes` mapping of the `ProxyAdminOwner` should change during the simulation.
See the ["Key Computation" section](../../../../../NESTED-VALIDATION.md#key-computation) in the nested validation doc
for instruction on how to validate this change.  The `$SAFE_HASH` value for this calculation should be:
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

<pre>
  <code>
----- DecodedStateDiff[0] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/sepolia/op.toml#L59">0x034edD2A225f7f429A63E0f1D2084B9E0A93b538</a>
  Contract:          SystemConfig - OP Sepolia Testnet
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Raw New Value:     0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647
  Decoded Kind:      address
  Decoded Old Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L9-L9">0x340f923E5c7cbB2171146f64169EC9d5a9FfE647</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[1] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L59-L59">0x05C993e60179f28bF649a2Bb5b00b5F4283bD525</a>
  Contract:          SystemConfig - Ink Sepolia
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Raw New Value:     0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647
  Decoded Kind:      address
  Decoded Old Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L9-L9">0x340f923E5c7cbB2171146f64169EC9d5a9FfE647</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[2] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/op.toml#L63-L63">0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1</a>
  Contract:          DisputeGameFactory - OP Sepolia Testnet
  Chain ID:          11155420
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x0000000000000000000000007717296cac5d39d362eb77a94c95483bebae214e
  Raw New Value:     0x000000000000000000000000845e5382d60ec16e538051e1876a985c5339cc62
  [WARN] Slot was not decoded
  Summary:           Set a new game implementation for game type <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55">1 (PERMISSIONED_CANNON)<a/>.
  Detail:            You can verify this slot corresponds to the game implementation for game type 1 by 
                     deriving the slot value as follows:
                     - Notice that <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57">`gameImpls` is a map from a `GameType` to a dispute game address</a>.
                     - Notice that `GameType` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224">equivalent to a `uint32`</a>.
                     - Notice that the `gameImpls` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41">stored at slot 101</a>. 
                     - Calculate the expected slot for game type 1 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                       - `cast index uint32 1 101`
                     - You should derive a value matching the "Raw Slot" here: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e

----- DecodedStateDiff[3] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/op.toml#L63-L63">0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1</a>
  Contract:          DisputeGameFactory - OP Sepolia Testnet
  Chain ID:          11155420
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x0000000000000000000000001851253ad7214f7b39e541befb6626669cb2446f
  Raw New Value:     0x000000000000000000000000d46b939123d5fb1b48ee3f90caebc9d5498ed542
  [WARN] Slot was not decoded
  Summary:           Set a new game implementation for game type <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52">0 (CANNON)<a/>.
  Detail:            You can verify this slot corresponds to the game implementation for game type 0 by 
                     deriving the slot value as follows:
                     - Notice that <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57">`gameImpls` is a map from a `GameType` to a dispute game address</a>.
                     - Notice that `GameType` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224">equivalent to a `uint32`</a>.                      
                     - Notice that the `gameImpls` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41">stored at slot 101</a>. 
                     - Calculate the expected slot for game type 0 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                       - `cast index uint32 0 101`
                     - You should derive a value matching the "Raw Slot" here: 0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b

----- DecodedStateDiff[4] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/op.toml#L58">0x16Fc5058F25648194471939df75CF27A2fdC48BC</a>
  Contract:          OptimismPortal2 - OP Sepolia Testnet
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Raw New Value:     0x000000000000000000000000b443da3e07052204a02d630a8933dac05a0d6fb4
  Decoded Kind:      address
  Decoded Old Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L13-L13">0xB443Da3e07052204A02d630a8933dAc05a0d6fB4</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[5] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-config-roles-sepolia.toml#L3">0x1Eb2fFc903729a0F03966B917003800b145F56E2</a>
  Contract:          ProxyAdminOwner (GnosisSafe)
  Chain ID:          11155420
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000019
  Raw New Value:     0x000000000000000000000000000000000000000000000000000000000000001a
  Decoded Kind:      uint256
  Decoded Old Value: 25
  Decoded New Value: 26
  Summary:           nonce
  Detail:

----- DecodedStateDiff[6] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L55-L55">0x2bfb22cd534a462028771a1cA9D6240166e450c4</a>
  Contract:          L1ERC721Bridge - Soneium Testnet Minato
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Raw New Value:     0x0000000000000000000000007ae1d3bd877a4c5ca257404ce26be93a02c98013
  Decoded Kind:      address
  Decoded Old Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L19-L19">0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[7] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L56-L56">0x33f60714BbD74d62b66D79213C348614DE51901C</a>
  Contract:          L1StandardBridge - Ink Sepolia
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Raw New Value:     0x0000000000000000000000000b09ba359a106c9ea3b181cbc5f394570c7d2a7a
  Decoded Kind:      address
  Decoded Old Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L20-L20">0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[8] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L53-L53">0x3454F9df5E750F1383e58c1CB001401e7A4f3197</a>
  Contract:          AddressManager - Ink Sepolia
  Chain ID:          763373
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  Raw New Value:     0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b
  [WARN] Slot was not decoded
  Summary:           The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v3.0.0-rc.2' L1CrossDomainMessenger at <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L18">0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231</a>.
  Detail:            This key is complicated to compute, so instead we attest to correctness of the key by
                     verifying that the "Before" value currently exists in that slot, as explained below.
                     <b>Before</b> address matches both of the following cast calls:
                      1. What is returned by calling `AddressManager.getAddress()`:
                       - <i>cast call 0x3454F9df5E750F1383e58c1CB001401e7A4f3197 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia</i>
                      2. What is currently stored at the key:
                       - <i>cast storage 0x3454F9df5E750F1383e58c1CB001401e7A4f3197 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url sepolia</i>

----- DecodedStateDiff[9] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L60-L60">0x4Ca9608Fef202216bc21D543798ec854539bAAd3</a>
  Contract:          SystemConfig - Soneium Testnet Minato
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Raw New Value:     0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647
  Decoded Kind:      address
  Decoded Old Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L9-L9">0x340f923E5c7cbB2171146f64169EC9d5a9FfE647</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[10] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L58-L58">0x5c1d29C6c9C8b0800692acC95D700bcb4966A1d7</a>
  Contract:          OptimismPortal2 - Ink Sepolia
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Raw New Value:     0x000000000000000000000000b443da3e07052204a02d630a8933dac05a0d6fb4
  Decoded Kind:      address
  Decoded Old Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L13-L13">0xB443Da3e07052204A02d630a8933dAc05a0d6fB4</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[11] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L56-L56">0x5f5a404A5edabcDD80DB05E8e54A78c9EBF000C2</a>
  Contract:          L1StandardBridge - Soneium Testnet Minato
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Raw New Value:     0x0000000000000000000000000b09ba359a106c9ea3b181cbc5f394570c7d2a7a
  Decoded Kind:      address
  Decoded Old Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L20-L20">0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[12] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L59-L59">0x65ea1489741A5D72fFdD8e6485B216bBdcC15Af3</a>
  Contract:          OptimismPortal2 - Soneium Testnet Minato
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Raw New Value:     0x000000000000000000000000b443da3e07052204a02d630a8933dac05a0d6fb4
  Decoded Kind:      address
  Decoded Old Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L13-L13">0xB443Da3e07052204A02d630a8933dAc05a0d6fB4</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[13] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L53-L53">0x6e8A77673109783001150DFA770E6c662f473DA9</a>
  Contract:          AddressManager - Soneium Testnet Minato
  Chain ID:          1946
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  Raw New Value:     0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b
  [WARN] Slot was not decoded
  Summary:           The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v3.0.0-rc.2' L1CrossDomainMessenger at <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L18">0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231</a>.
  Detail:            This key is complicated to compute, so instead we attest to correctness of the key by
                     verifying that the "Before" value currently exists in that slot, as explained below.
                     <b>Before</b> address matches both of the following cast calls:
                      1. What is returned by calling `AddressManager.getAddress()`:
                       - <i>cast call 0x6e8A77673109783001150DFA770E6c662f473DA9 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia</i>
                      2. What is currently stored at the key:
                       - <i>cast storage 0x6e8A77673109783001150DFA770E6c662f473DA9 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url sepolia</i>
  

----- DecodedStateDiff[14] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/ink.toml#L64">0x860e626c700AF381133D9f4aF31412A2d1DB3D5d</a>
  Contract:          DisputeGameFactory - Ink Sepolia
  Chain ID:          763373
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x00000000000000000000000065e5ec10f922cf7e61ead974525a2795bd4fda9a
  Raw New Value:     0x000000000000000000000000de2b69153c42191eb4863a36024d80a1d426d0c8
  [WARN] Slot was not decoded
  Summary:           Set a new game implementation for game type <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55">1 (PERMISSIONED_CANNON)<a/>.
  Detail:            You can verify this slot corresponds to the game implementation for game type 1 by 
                     deriving the slot value as follows:
                     - Notice that <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57">`gameImpls` is a map from a `GameType` to a dispute game address</a>.
                     - Notice that `GameType` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224">equivalent to a `uint32`</a>.
                     - Notice that the `gameImpls` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41">stored at slot 101</a>. 
                     - Calculate the expected slot for game type 1 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                       - `cast index uint32 1 101`
                     - You should derive a value matching the "Raw Slot" here: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e

----- DecodedStateDiff[15] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/ink.toml#L64">0x860e626c700AF381133D9f4aF31412A2d1DB3D5d</a>
  Contract:          DisputeGameFactory - Ink Sepolia
  Chain ID:          763373
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x00000000000000000000000043736de4bd35482d828b79ea673b76ab1699626f
  Raw New Value:     0x0000000000000000000000000c356f533eb009deb302bc96522e80dea6a16276
  [WARN] Slot was not decoded
  Summary:           Set a new game implementation for game type <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52">0 (CANNON)<a/>.
  Detail:            You can verify this slot corresponds to the game implementation for game type 0 by 
                     deriving the slot value as follows:
                     - Notice that <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57">`gameImpls` is a map from a `GameType` to a dispute game address</a>.
                     - Notice that `GameType` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224">equivalent to a `uint32`</a>.                      - Notice that the `gameImpls` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41">stored at slot 101</a>. 
                     - Calculate the expected slot for game type 0 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                       - `cast index uint32 0 101`
                     - You should derive a value matching the "Raw Slot" here: 0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b

----- DecodedStateDiff[16] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/op.toml#L53-L53">0x9bFE9c5609311DF1c011c47642253B78a4f33F4B</a>
  Contract:          AddressManager - OP Sepolia Testnet
  Chain ID:          11155420
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  Raw New Value:     0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b
  [WARN] Slot was not decoded
  Summary:           The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v3.0.0-rc.2' L1CrossDomainMessenger at <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L18">0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231</a>.
  Detail:            This key is complicated to compute, so instead we attest to correctness of the key by
                     verifying that the "Before" value currently exists in that slot, as explained below.
                     <b>Before</b> address matches both of the following cast calls:
                      1. What is returned by calling `AddressManager.getAddress()`:
                       - <i>cast call 0x9bFE9c5609311DF1c011c47642253B78a4f33F4B 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia</i>
                      2. What is currently stored at the key:
                       - <i>cast storage 0x9bFE9c5609311DF1c011c47642253B78a4f33F4B 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url sepolia</i>

----- DecodedStateDiff[17] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/soneium-minato.toml#L64">0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01</a>
  Contract:          DisputeGameFactory - Soneium Testnet Minato
  Chain ID:          1946
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x0000000000000000000000002087cbc6ec893a31405d56025cd1ae648da3982c
  Raw New Value:     0x000000000000000000000000697a4684576d8a76d4b11e83e9b6f3b61bf04755
  [WARN] Slot was not decoded
  Summary:           Set a new game implementation for game type <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55">1 (PERMISSIONED_CANNON)<a/>.
  Detail:            You can verify this slot corresponds to the game implementation for game type 1 by 
                     deriving the slot value as follows:
                     - Notice that <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57">`gameImpls` is a map from a `GameType` to a dispute game address</a>.
                     - Notice that `GameType` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224">equivalent to a `uint32`</a>.
                     - Notice that the `gameImpls` is <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41">stored at slot 101</a>. 
                     - Calculate the expected slot for game type 1 using `cast index &lt;KEY_TYPE&gt; &lt;KEY&gt; &lt;SLOT_NUMBER&gt;`:
                       - `cast index uint32 1 101`
                     - You should derive a value matching the "Raw Slot" here: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e

----- DecodedStateDiff[18] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/ink.toml#L55-L55">0xd1C901BBD7796546A7bA2492e0E199911fAE68c7</a>
  Contract:          L1ERC721Bridge - Ink Sepolia
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Raw New Value:     0x0000000000000000000000007ae1d3bd877a4c5ca257404ce26be93a02c98013
  Decoded Kind:      address
  Decoded Old Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L19-L19">0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[19] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/op.toml#L55">0xd83e03D576d23C9AEab8cC44Fa98d058D2176D1f</a>
  Contract:          L1ERC721Bridge - Op Sepolia Testnet
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Raw New Value:     0x0000000000000000000000007ae1d3bd877a4c5ca257404ce26be93a02c98013
  Decoded Kind:      address
  Decoded Old Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L19-L19">0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[20] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/op.toml#L56-L56">0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1</a>
  Contract:          L1StandardBridge - OP Sepolia Testnet
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Raw New Value:     0x0000000000000000000000000b09ba359a106c9ea3b181cbc5f394570c7d2a7a
  Decoded Kind:      address
  Decoded Old Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L20-L20">0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[21] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/validation/standard/standard-versions-sepolia.toml#L22-L22">0xfBceeD4DE885645fBdED164910E10F52fEBFAB35</a>
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  [WARN] Slot was not decoded
  Summary:           <b>IMPORTANT: THIS STATE CHANGE MAY NOT APPEAR IN THE TENDERLY STATE DIFF.</b>
                     <i>isRC</i> storage slot updated to 0.
  Detail:            Once OPContractsManager is upgraded, the <i>isRC</i> flag is set to false.
                     This happens in the first invocation of the <i>upgrade</i> function.
                     Slot 22 is the <i>isRC</i> flag: <i>cast to-hex 22</i> -> <i>0x16</i>.
                     Please refer to <i>'Figure 0.1'</i> at the end of this report for the storage layout of OPContractsManager.
  </code>
 </pre>

# Supplementary Material

## Figure 0.1: Storage Layout of OPContractsManager

![OPContractsManager isRC flag set to false](./images/op-contracts-manager-storage-layout.png)
