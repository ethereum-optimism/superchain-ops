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
> ### Child Safe 1: `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC` (Unichain)
>
> - Domain Hash: `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `TODO`
>
> ### Child Safe 2: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Optimism Foundation)
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `TODO`
>
> ### Child Safe 3: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `TODO`


## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Unichain Mainnet:
    - SystemConfigProxy: [0xc407398d063f942feBbcC6F80a156b47F3f1BDA6](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/unichain.toml#L58)
    - ProxyAdmin: [0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/unichain.toml#L59)
    - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://www.notion.so/oplabs/Upgrade-14-MTCannon-1d6f153ee1628024af26cd0098d3bdfe?pvs=4)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xc407398d063f942feBbcC6F80a156b47F3f1BDA6, 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4, 0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L60) - Mainnet OPContractsManager v2.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000026b2f158255beac46c1e7c6b8bbf29a4b6a7b760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-14-isthmus-l1-contracts-mt-cannon/9796#p-43948-action-plan-9) section of the Governance proposal.

# State Changes

## Single Safe State Overrides and Changes

This task is executed by the single `ProxyAdminOwner` Safe. Refer to the [generic single Safe execution validation document](../../../../../SINGLE-VALIDATION.md)
for the expected state overrides and changes.

Additionally, Safe-related nonces [will increment by one](../../../../../SINGLE-VALIDATION.md#nonce-increments).

## Other Nonces

In addition to the Safe-related nonces mentioned [previously](#single-safe-state-overrides-and-changes), new contracts will also have a nonce value increment from 0 to 1.
This is due to [EIP-161](https://eips.ethereum.org/EIPS/eip-161) which activated in 2016.

This affects the newly deployed dispute games mentioned in ["State Diffs"](#state-diffs).

## State Diffs

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

  ---

### `0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2`  (OptimismPortal2) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** `0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

**<TODO: Insert links for this state change then remove this line.>**

  ---

### `0x2f12d621a16e2d3285929c9996f478508951dfe4`  (DisputeGameFactory) - Chain ID: 130

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x0000000000000000000000005fe2becc3dec340d3df04351db8e728cbe4c7450`
  - **After:**     `0x00000000000000000000000067d59ac1166ba17612be0edf275187e38cbf9b99`
  - **Summary:**
  - **Detail:**

**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**

**<TODO: Insert links for this state change then remove this line.>**


- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x000000000000000000000000d2c3c6f4a4c5aa777bd6c476aea58439db0dd844`
  - **After:**     `0x00000000000000000000000056ebb9eae4f33ceaed3672446e3812d77f8a8a2c`
  - **Summary:**
  - **Detail:**

**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**

**<TODO: Insert links for this state change then remove this line.>**

  ---

### `0x6d5b183f538abb8572f5cd17109c617b994d5833`  (ProxyAdminOwner (GnosisSafe)) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `3`
  - **After:** `4`
  - **Summary:**           nonce
  - **Detail:**

**<TODO: Insert links for this state change then remove this line.>**

  ---

### `0x8098f676033a377b9defe302e9fe6877cd63d575`  (AddressManager) - Chain ID: 130

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:**     `0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **Summary:**
  - **Detail:**

**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**

**<TODO: Insert links for this state change then remove this line.>**

  ---

### `0x81014f44b0a345033bb2b3b21c7a1a308b35feea`  (L1StandardBridge) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** `0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

**<TODO: Insert links for this state change then remove this line.>**

  ---

### `0xc407398d063f942febbcc6f80a156b47f3f1bda6`  (SystemConfig) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** `0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

**<TODO: Insert links for this state change then remove this line.>**

  ---

### `0xd04d0d87e0bd4d2e50286760a3ef323fea6849cf`  (L1ERC721Bridge) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

**<TODO: Insert links for this state change then remove this line.>**
