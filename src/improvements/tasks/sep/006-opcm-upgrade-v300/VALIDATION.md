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
> ### Nested Safe 1: `0x6AF0674791925f767060Dd52f7fB20984E8639d8` 
>
> - Domain Hash: ``
> - Message Hash: ``
>
> ### Nested Safe 2: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`
>
> - Domain Hash: ``
> - Message Hash: ``

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Base Sepolia Testnet:
    - SystemConfigProxy: [0xf272670eb55e895584501d564AfEB048bEd26194](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L59)
    - ProxyAdmin: [0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L60)
    - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/validation/standard/standard-prestates.toml#L18)


Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xf272670eb55e895584501d564AfEB048bEd26194, 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3, 0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0xfBceeD4DE885645fBdED164910E10F52fEBFAB35](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L22) - Sepolia OPContractsManager v3.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xfBceeD4DE885645fBdED164910E10F52fEBFAB35,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fbceed4de885645fbded164910e10f52febfab350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000
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

  ---
  
### `0x0fe884546476ddd290ec46318785046ef68a0ba9 (ProxyAdminOwner (GnosisSafe))`
  
#### Decoded State Change: 0
  - **Contract:**          `ProxyAdminOwner (GnosisSafe)`
  - **Chain ID:**          `84532`
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `20`
  - **After:** `21`
  
- **Summary:**           nonce
  - **Detail:**            
  
**TODO: Insert links for this state change.**

  ---
  
### `0x21efd066e581fa55ef105170cc04d74386a09190 (L1ERC721Bridge)`
  
#### Decoded State Change: 1
  - **Contract:**          `L1ERC721Bridge`
  - **Chain ID:**          `84532`
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  
- **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**TODO: Insert links for this state change.**

  ---
  
### `0x49f53e41452c74589e85ca1677426ba426459e85 (OptimismPortal2)`
  
#### Decoded State Change: 2
  - **Contract:**          `OptimismPortal2`
  - **Chain ID:**          `84532`
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** `0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`
  
- **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**TODO: Insert links for this state change.**

  ---
  
### `0x709c2b8ef4a9fefc629a8a2c1af424dc5bd6ad1b (AddressManager)`
  
#### Decoded State Change: 3
  - **Contract:**          `AddressManager`
  - **Chain ID:**          `84532`
  
- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:**     `0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  
- **Summary:**           
  - **Detail:**            
  
[WARN] Slot was not decoded. Please manually decode and provide a summary with the detail then remove this warning.
  
**TODO: Insert links for this state change.**

  ---
  
### `0xd6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1 (DisputeGameFactory)`
  
#### Decoded State Change: 4
  - **Contract:**          `DisputeGameFactory`
  - **Chain ID:**          `84532`
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x000000000000000000000000d53394d4f67653074acf0b264954fe5e4f72d24f`
  - **After:**     `0x0000000000000000000000006f67e57c143321e266bac32a0d9d22d88ce1b3e5`
  
- **Summary:**           
  - **Detail:**            
  
[WARN] Slot was not decoded. Please manually decode and provide a summary with the detail then remove this warning.
  
**TODO: Insert links for this state change.**

  
#### Decoded State Change: 5
  - **Contract:**          `DisputeGameFactory`
  - **Chain ID:**          `84532`
  
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x000000000000000000000000861eb6dfe0fde8c8a63e8606fa487ee870f65e72`
  - **After:**     `0x000000000000000000000000340c1364d299ed55b193d4efcecbad8c3fb104c4`
  
- **Summary:**           
  - **Detail:**            
  
[WARN] Slot was not decoded. Please manually decode and provide a summary with the detail then remove this warning.
  
**TODO: Insert links for this state change.**

  ---
  
### `0xf272670eb55e895584501d564afeb048bed26194 (SystemConfig)`
  
#### Decoded State Change: 6
  - **Contract:**          `SystemConfig`
  - **Chain ID:**          `84532`
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** `0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`
  
- **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**TODO: Insert links for this state change.**

  ---
  
### `0xfd0bf71f60660e2f608ed56e1659c450eb113120 (L1StandardBridge)`
  
#### Decoded State Change: 7
  - **Contract:**          `L1StandardBridge`
  - **Chain ID:**          `84532`
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** `0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`
  
- **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**TODO: Insert links for this state change.**

# Supplementary Material
