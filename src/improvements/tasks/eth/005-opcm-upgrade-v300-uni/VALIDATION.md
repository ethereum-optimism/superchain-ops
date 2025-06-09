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
> - Message Hash: `0x8d6e401e38edc31dbfef4dc3ecc0ff0391c9e30ae9b6fb8ff8121d0afcb9824d`
>
> ### Child Safe 2: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Optimism Foundation)
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x1d58e937f6530c6dd2bd40784894a44be093f6c13d75fc97bfda60c6578f8e20`
>
> ### Child Safe 3: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x931197752921d464fede71b237583d933e3b654b133707a191056c0d986c9dc9`

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

- `target`: [0x3a1f523a4bc09cd344a2745a108bb0398288094f](https://github.com/ethereum-optimism/superchain-registry/blob/b3d020de42abeebeb5786ea5508aa08d12bdf4cd/validation/standard/standard-versions-mainnet.toml#L22) - Mainnet OPContractsManager v3.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x3a1f523a4bc09cd344a2745a108bb0398288094f,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003a1f523a4bc09cd344a2745a108bb0398288094f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-14-isthmus-l1-contracts-mt-cannon/9796#p-43948-action-plan-9) section of the Governance proposal.

# State Changes

## Single Safe State Overrides and Changes

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

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

### [`0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/unichain.toml#L57)  (OptimismPortal2) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** [`0xb443da3e07052204a02d630a8933dac05a0d6fb4`](https://github.com/ethereum-optimism/superchain-registry/blob/51804a33655ddb4feeb0ad88960d9a81acdf6e62/validation/standard/standard-versions-mainnet.toml#L13)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
    OptimismPortal2 contract for `op-contracts/v3.0.0`.

  ---

### [`0x24424336f04440b1c28685a38303ac33c9d14a25`](https://etherscan.io/address/0x24424336f04440b1c28685a38303ac33c9d14a25) (Foundation LivenessGuard)

> [!IMPORTANT]
> Foundation Only

- **Key:**          `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
-
  - **Before:**     `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:**     `0x0000000000000000000000000000000000000000000000000000000067f7ef19`
  - **Summary:**   LivenessGuard timestamp update.
  - **Detail:**    **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE FOUNDATION AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**
                   When the security council safe executes a transaction, the liveness timestamps are updated.
                   This is updating at the moment when the  transaction is submitted (`block.timestamp`) into the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol#L41) mapping located at the slot 0.

  ---

### [`0x2F12d621a16e2d3285929C9996f478508951dFe4`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/unichain.toml#L63)  (DisputeGameFactory) - Chain ID: 130

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`

  - **Before:**     `0x0000000000000000000000005fe2becc3dec340d3df04351db8e728cbe4c7450`
  - **After:**     `0x00000000000000000000000067d59ac1166ba17612be0edf275187e38cbf9b99`
  - **Summary:**  Set a new game implementation for game type [PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    You can verify this slot corresponds to the game implementation for game type 1 by deriving the slot value as follows:
    - Notice that [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is a map from a `GameType` to a dispute game address.
    - Notice that `GameType` is [equivalent to a](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224) `uint32`.
    - Notice that the `gameImpls` is [stored at slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41).
    - Calculate the expected slot for game type 1 using `cast index <KEY_TYPE> <KEY> <SLOT_NUMBER>`:
    - `cast index uint32 1 101`
    - You should derive a value matching the "Raw Slot" here: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`

  - **Before:**     `0x000000000000000000000000d2c3c6f4a4c5aa777bd6c476aea58439db0dd844`
  - **After:**     `0x00000000000000000000000056ebb9eae4f33ceaed3672446e3812d77f8a8a2c`
  - **Summary:**  Set a new game implementation for game type [CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    You can verify this slot corresponds to the game implementation for game type 0 by deriving the slot value as follows:
    - Notice that [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is a map from a `GameType` to a dispute game address.
    - Notice that `GameType` is [equivalent to a](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224) `uint32`.
    - Notice that the `gameImpls` is [stored at slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41).
    - Calculate the expected slot for game type 0 using `cast index <KEY_TYPE> <KEY> <SLOT_NUMBER>`:
    - `cast index uint32 0 101`
    - You should derive a value matching the "Raw Slot" here: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`

  ---

### [`0x6d5B183F538ABB8572F5cD17109c617b994D5833`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/unichain.toml#L44)  (ProxyAdminOwner (GnosisSafe)) - Chain ID: 130

- **Nonce:**
  - **Before:** 4
  - **After:** 6
  - **Detail:** Two new dispute games were deployed by the ProxyAdminOwner during execution, resulting in the account nonce being incremented twice.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `3`
  - **After:** `4`
  - **Summary:**           nonce
  - **Detail:**            The nonce of the ProxyAdminOwner contract is updated.

- **Key:** Depending on which child safe is being used:  <br/>
  **Unichain**: `0xd933059d587e09e3c1d3d0056ab9246d0ab102abd5a0dbec43ccae45a87bfa57` or<br/>
  **Foundation**: `0xfcda2750e0678aba47833e49ab511d900c078a75599f9ac8d5f9ffceba130696` or <br/>
  **Security council**: `0xc6bf1a0b91980d7374cb69e1ce46fbaf261f74f7b98ceb364479114dd3656c30
  - **Decoded Kind:**      `uint256`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:**  **THE KEY COMPUTATION WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    **SIGNERS SHOULD STILL VERIFY THAT THE CORRECT KEY APPEARS IN THE SIMULATION**
  As part of the Tenderly simulation, we want to illustrate the `approveHash` invocation.
    This step isn't shown in the local simulation because the parent multisig is invoked directly,
    bypassing the `approveHash` calls.
    This slot change reflects an update to the `approvedHashes` mapping.

    If this simulation was run as the child safe `0xb0c4c487c5cf6d67807bc2008c66fa7e2ce744ec` (Unichain):
    - `res=$(cast index address 0xb0c4c487c5cf6d67807bc2008c66fa7e2ce744ec 8)`
    - `cast index bytes32 0xdc1e62cfd7e0f70e33179b0a59e3579936c0152298088dd3252c5813a6432b27 $res`
    - returns `0xd933059d587e09e3c1d3d0056ab9246d0ab102abd5a0dbec43ccae45a87bfa57`

    If this simulation was run as the child safe `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation):
    - `res=$(cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8)`
    - `cast index bytes32 0xdc1e62cfd7e0f70e33179b0a59e3579936c0152298088dd3252c5813a6432b27 $res`
    - returns `0xfcda2750e0678aba47833e49ab511d900c078a75599f9ac8d5f9ffceba130696`

    If this simulation was run as the child safe `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council):
    - `res=$(cast index address 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 8)`
    - `cast index bytes32 0xdc1e62cfd7e0f70e33179b0a59e3579936c0152298088dd3252c5813a6432b27 $res`
    - Alternative 'Raw Slot': `0x52ae8914197b131df3798d231a9ba1ab02adf66da792b6f3a826e88e5c54ecd5`
    - returns `0xc6bf1a0b91980d7374cb69e1ce46fbaf261f74f7b98ceb364479114dd3656c30`
  - Please note: the `0xdc1e62cfd7e0f70e33179b0a59e3579936c0152298088dd3252c5813a6432b27` value is taken from the Tenderly simulation and this is the transaction hash of the `approveHash` call.

  ---

### [`0x8098F676033A377b9Defe302e9fE6877cD63D575`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/unichain.toml#L52)  (AddressManager) - Chain ID: 130

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:**     `0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **Summary:**  The name `OVM_L1CrossDomainMessenger` is set to the address of the new `op-contracts/v3.0.0` L1CrossDomainMessenger implementation at [`0x5d5a095665886119693f0b41d8dfee78da033e8b`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L18).
  - **Detail: **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    This key is complicated to compute, so instead we attest to correctness of the key by
    verifying that the "Before" value currently exists in that slot, as explained below.
    **Before** address matches the following cast call to `AddressManager.getAddress()`:
    - `cast call 0x8098F676033A377b9Defe302e9fE6877cD63D575 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url mainnet`
      And what is currently stored at the key:
    - `cast storage 0x8098F676033A377b9Defe302e9fE6877cD63D575 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url mainnet`
    - returns: `0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231`

  ---

### [`0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/unichain.toml#L55)  (L1StandardBridge) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** `0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
    The implementation of the L1StandardBridge contract is set to [`0x0b09ba359a106c9ea3b181cbc5f394570c7d2a7a`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L20) for `op-contracts/v3.0.0`.

  ---

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council - Child Safe 3)

> [!IMPORTANT]
> Security Council Only

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `24`
  - **After:** `25`
  - **Summary:**           nonce
  - **Detail:**            The nonce of the signing safe contract is updated.
    **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE SECURITY SAFE.**

  ---


### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation - Child Safe 2)

> [!IMPORTANT]
> Foundation Only

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `22`
  - **After:** `23`
  - **Summary:**           nonce
  - **Detail:**            The nonce of the signing safe contract is updated.
    **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE FOUNDATION SAFE.**

  ---

### `0x9343c452dec3251fe99D9Fd29b74c5b9CD1751a6` (Unichain LivenessGuard) - Chain ID: 130

> [!IMPORTANT]
> Unichain Safe Only

- **Key:**          `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
-
  - **Before:**     `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:**     `0x0000000000000000000000000000000000000000000000000000000067f7ef19`
  - **Summary:**   LivenessGuard timestamp update.
  - **Detail:**    **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR UNICHAIN AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**
                   When the security council safe executes a transaction, the liveness timestamps are updated.
                   This is updating at the moment when the  transaction is submitted (`block.timestamp`) into the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol#L41) mapping located at the slot 0.

  ---

### `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC` (Unichain - Child Safe 1)

> [!IMPORTANT]
> Unichain Safe Only

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `9`
  - **After:** `10`
  - **Summary:**           nonce
  - **Detail:**            The nonce of the signing safe is updated.
    **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE UNICHAIN SAFE.**

  ---

### [`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/unichain.toml#L58)  (SystemConfig) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** `0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  The implementation of the SystemConfig contract is set to [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L9) for `op-contracts/v3.0.0`.

  ---

### [`0xd04d0d87e0bd4d2e50286760a3ef323fea6849cf`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/unichain.toml#L54)  (L1ERC721Bridge) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  The implementation of the L1ERC721Bridge contract is set to [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L19) for `op-contracts/v3.0.0`.

### Nonce increments

The only other state change are the nonce increments as follows:

- sender-address - Sender address of the Tenderly transaction (Your ledger address).
- `0x56ebb9eaE4f33ceaED3672446E3812D77F8a8A2c` - Permissionless GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0x67d59AC1166bA17612BE0Edf275187E38Cbf9B99` - Permissioned GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
