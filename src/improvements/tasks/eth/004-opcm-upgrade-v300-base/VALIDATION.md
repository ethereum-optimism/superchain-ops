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
> ### Base Operations Multisig - `0x9855054731540A48b28990B63DcF4f33d8AE46A1`
>
> - Domain Hash: `0x88aac3dc27cc1618ec43a87b3df21482acd24d172027ba3fbb5a5e625d895a0b`
> - Message Hash: `0xfdf1e28011d0975ba7f55f16844c4a4a166897f289bc9f3a852b67f12d68218e`
>
> ### Optimism Foundation - `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`
>
> - Domain Hash: `0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890`
> - Message Hash: `0xa4472e9d5c2fa87cc744a492bf8326f7ec29f3de4a508c055ccb1d0175c5833f`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v3.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Base:
    - SystemConfigProxy: [0x73a79Fab69143498Ed3712e519A88a918e1f4072](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/base.toml#L59)
    - ProxyAdmin: [0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/base.toml#L60)
    - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://www.notion.so/oplabs/Upgrade-14-MTCannon-1d6f153ee1628024af26cd0098d3bdfe?pvs=4)

Thus, the command to encode the calldata is:


```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x73a79Fab69143498Ed3712e519A88a918e1f4072,0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E,0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0x3a1f523a4bc09cd344a2745a108bb0398288094f](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L22) - Mainnet OPContractsManager v3.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x3a1f523a4bc09cd344a2745a108bb0398288094f,false,0xff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003a1f523a4bc09cd344a2745a108bb0398288094f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-14-isthmus-l1-contracts-mt-cannon/9796#p-43948-action-plan-9) section of the Governance proposal.

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

### [`0x3154Cf16ccdb4C6d922629664174b904d80F2C35`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/superchain/configs/mainnet/base.toml#L55)  (L1StandardBridge) - Chain ID: 8453
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** [`0x0b09ba359a106c9ea3b181cbc5f394570c7d2a7a`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/validation/standard/standard-versions-mainnet.toml#L20)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### [`0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/superchain/configs/mainnet/base.toml#L63)  (DisputeGameFactory) - Chain ID: 8453
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x0000000000000000000000008bd2e80e6d1cf1e5c5f0c69972fe2f02b9c046aa`
  - **After:**     `0x000000000000000000000000e749aa49c3edaf1dcb997ea3dac23dff72bcb826`
  - **Summary:**           
  - **Detail:**            
  
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x00000000000000000000000013fbbdefa7d9b147a1777a8a5b0f30379e007ac3`
  - **After:**     `0x000000000000000000000000e17d670043c3cdd705a3223b3d89a228a1f07f0f`
  - **Summary:**           
  - **Detail:**            

  ---
  
### [`0x49048044D57e1C92A77f79988d21Fa8fAF74E97e`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/superchain/configs/mainnet/base.toml#L58)  (OptimismPortal2) - Chain ID: 8453
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** [`0xb443da3e07052204a02d630a8933dac05a0d6fb4`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/validation/standard/standard-versions-mainnet.toml#L13)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### [`0x608d94945A64503E642E6370Ec598e519a2C1E53`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/superchain/configs/mainnet/base.toml#L54)  (L1ERC721Bridge) - Chain ID: 8453
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** [`0x7ae1d3bd877a4c5ca257404ce26be93a02c98013`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/validation/standard/standard-versions-mainnet.toml#L19)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### [`0x73a79Fab69143498Ed3712e519A88a918e1f4072`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/superchain/configs/mainnet/base.toml#L59)  (SystemConfig) - Chain ID: 8453
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** [`0x340f923e5c7cbb2171146f64169ec9d5a9ffe647`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/validation/standard/standard-versions-mainnet.toml#L9)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### [`0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/superchain/configs/mainnet/base.toml#L44)  (ProxyAdminOwner (GnosisSafe)) - Chain ID: 8453
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `7`
  - **After:** `8`
  - **Summary:**           nonce
  - **Detail:**            
  
  ---
  
### [`0x8EfB6B5c4767B09Dc9AA6Af4eAA89F749522BaE2`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/superchain/configs/mainnet/base.toml#L52)  (AddressManager) - Chain ID: 8453
  
- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:**     `0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **Summary:**           
  - **Detail:**            
