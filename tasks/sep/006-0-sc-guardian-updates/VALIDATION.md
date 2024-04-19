# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xa87675ebb9501C7baE8570a431c108C1577478Fa` (The Security Council Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xa87675ebb9501C7baE8570a431c108C1577478Fa)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

### `0x54e8baccc67fa3c6b3e9a94baa4d70d1668f0820` (`LivenessGuard`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x54e8baccc67fa3c6b3e9a94baa4d70d1668f0820) (not verified)

State Changes:
- **Key:** `0x023c107741c8297b7d31ce48158a7d3e0c1bab34eb099ba05b48e6e0bb5b0324` <br/>
  **Before:** `0x000000000000000000000000000000000000000000000000000000006620aaa4` <br/>
  **After:** `0x000000000000000000000000000000000000000000000000000000006621dcfe` <br/>
  **Meaning:** The 'lastLive' timestamp of the caller has been updated. The key can be verified by:
    1. Seeing that the [slot of the mapping is 0](https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/snapshots/storageLayout/LivenessGuard.json#L6).
    2. Obtaining the storage key with `cast`, where the address provided should be the one used to simulate.
      ```shell
        cast index address 0x2e2e33fedd27fdecfc851ae98e45a5ecb76904fe 0
        0x023c107741c8297b7d31ce48158a7d3e0c1bab34eb099ba05b48e6e0bb5b0324
      ```
    3. The timestamp should be from a recent block, and can be decoded from the value with:
      ```shell
        cast to-dec 0x000000000000000000000000000000000000000000000000000000006621dcfe
        1713495294
      ```

- **Key**: `0x56ee16ca3ade18209faccff732edefbb77524a2f2c0c642df2abe4924871e783` <br/>
  **Before**: `0x000000000000000000000000000000000000000000000000000000006620aaa4` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning:** The 'lastLive' timestamp of the removed owner has been deleted. The key can be verified by:
    1. Seeing that the [slot of the mapping is 0](https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/snapshots/storageLayout/LivenessGuard.json#L6).
    2. obtaining the storage key with `cast`, where the address provided should be the one used to simulate.
      ```shell
        cast index address 0x78339d822c23D943E4a2d4c3DD5408F66e6D662D 0
        0x56ee16ca3ade18209faccff732edefbb77524a2f2c0c642df2abe4924871e783
      ```

### `0xa87675ebb9501c7bae8570a431c108c1577478fa` (`GnosisSafe`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xa87675ebb9501c7bae8570a431c108c1577478fa)

State Changes:

- **Owner count:** reduced from 10 to 9, because of the removed owner.
- **Threshold:** increased from 1 to 2 (this change only occurs due to the state override required for the simulation)
- **Owners mapping:** The deployer `0x78339d822c23D943E4a2d4c3DD5408F66e6D662D` removed from the linked list of owners.
  - `0x78339d822c23d943e4a2d4c3dd5408f66e6d662d` no longer maps to `0x1` (the [sentinel owner](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/base/OwnerManager.sol#L17))
  - `0xea96f8d33af98839c20547d970ee0961f8865009` now maps to `0x1`
- **Modules mapping:** The Liveness module (`0xefd7...`) is inserted into the liked list of modules.
  - `0x1` now maps to `0xefd77c23a8acf13e194d30c6df51f1c43b0f9932`
  - `0xefd77C23A8ACF13E194d30C6DF51F1C43B0f9932` now maps to `0x2329efd0bfc72aa7849d9dfc2e131d83f4680d85` (the DeputyGuardianModule)

### `0xa87675ebb9501C7baE8570a431c108C1577478Fa` (The Security Council Safe)

The nonce is increased by 1.
