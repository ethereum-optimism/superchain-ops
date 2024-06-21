# VALIDATION

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (The 2/2 `ProxyAdmin` Owner)

Links:
- [Etherscan](https://etherscan.io/address/0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A)

Overrides:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** Enables the simulation by setting the threshold to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Council Safe) or `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Safe)

Links:
- [Etherscan (Council Safe)](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd03). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.
- [Etherscan (Foundation Safe)](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.

The Safe you are signing for will have the following overrides which will set the [Multicall](https://etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The number of owners is set to 1. The key can be validated by the location of the `ownerCount` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L13).

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

The following two overrides are modifications to the [`owners` mapping](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L12). For the purpose of calculating the storage, note that this mapping is in slot `2`.
This mapping implements a linked list for iterating through the list of owners. Since we'll only have one owner (Multicall), and the `0x01` address is used as the first and last entry in the linked list, we will see the following overrides:
- `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`
- `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`

And we do indeed see these entries:

- **Key:** 0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** This is `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`, so the key can be
    derived from `cast index address 0xca11bde05977b3631167028862be2a173976ca11 2`.

- **Key:** 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 <br/>
  **Value:** 0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11 <br/>
  **Meaning:** This is `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 2`.

## State Changes

### `0xe5965ab5962edc7477c8520243a95517cd252fa9` (`DisputeGameFactoryProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0xe5965ab5962edc7477c8520243a95517cd252fa9)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/extra/addresses/mainnet/op.json)

State Changes:
**Note:** The `101` referenced below is the storage slot of `gameImpls` defined in the [DisputeGameFactory storage layout](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L37C1-L43C5).

- **Key:** `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before:** `0x000000000000000000000000e9dad167ef4de8812c1abd013ac9570c616599a0` <br/>
  **After:** [`0x000000000000000000000000c307e93a7c530a184c98eade4545a412b857b62f`](https://etherscan.io/address/0xc307e93a7c530a184c98eade4545a412b857b62f) <br/>
  **Meaning:** This is `gameImpls[0] -> 0xc307e93a7c530a184c98eade4545a412b857b62f` (where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28), so the key can be derived from `cast index uint32 0 101`.

- **Key:** `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before:** `0x0000000000000000000000004146df64d83acb0dcb0c1a4884a16f090165e122` <br/>
  **After:** [`0x000000000000000000000000f691f8a6d908b58c534b624cf16495b491e633ba`](https://etherscan.io/address/0xf691f8a6d908b58c534b624cf16495b491e633ba) <br/>
  **Meaning:** This is `gameImpls[1] -> 0xf691f8a6d908b58c534b624cf16495b491e633ba` (where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31)), so the key can be derived from `cast index uint32 0 101`.

### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (The 2/2 `ProxyAdmin` Owner)

State Changes:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Meaning:** The nonce is increased from 4 to 5. The key can be validated by the location of the nonce variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

#### For the Council:

- **Key:** `0x0f7b79f6b38abe5e02d33eec6fcdf7d9447ff17f6803d46f0afd5f628bac8504` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L20)
      - The address of the Council Safe: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
      - The safe hash to approve: `0x530085da61c08016f1625301df4686fcfe40291b98db29a4bf801237ca3098c4`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 8
        0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
        ```
        and
      ```shell
        $ cast index bytes32 0x530085da61c08016f1625301df4686fcfe40291b98db29a4bf801237ca3098c4 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
        0x0f7b79f6b38abe5e02d33eec6fcdf7d9447ff17f6803d46f0afd5f628bac8504 
        ```
      And so the output of the second command matches the key above.

#### For the Foundation:

- **Key:** `0x6ef669e1a6fdba12525f568b5f98f3455726b23f9e33a5034c9180ca01a3f223` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L20)
      - The address of the Foundation Safe: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
      - The safe hash to approve: `0x530085da61c08016f1625301df4686fcfe40291b98db29a4bf801237ca3098c4`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8
        0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
      ```
      and
      ```shell
        $ cast index bytes32 0x530085da61c08016f1625301df4686fcfe40291b98db29a4bf801237ca3098c4 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
        0x6ef669e1a6fdba12525f568b5f98f3455726b23f9e33a5034c9180ca01a3f223 
      ```
      And so the output of the second command matches the key above.


### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Council Safe)

State Changes:

#### For the Council:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **Meaning:** The nonce is increased from 5 to 6. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).


### `0x847b5c174615b1b7fdf770882256e2d3e95b9d92` (Foundation Safe)

State Changes:

#### For the Foundation:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **Meaning:** The nonce is increased from 5 to 6. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17). Note that if this task is simulated before 011 has executed, then the nonce should be increased from 4 to 5.

### `0x24424336F04440b1c28685a38303aC33C9D14a25` (`LivenessGuard`)

State Changes:

#### For the Council:

- **Key:** `0x24424336f04440b1c28685a38303ac33c9d14a25` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000000000000000000000000000000000006675b61f` <br/>
  **Meaning:** This updates the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.5.0/packages/contracts-bedrock/src/Safe/LivenessGuard.sol#L36) indicating liveness of an owner that participated in signing. This will be updated to a block timestamp that's close to when this task was executed. Note that the "before" value may be non-zero for signers that have participated in signing prior.
