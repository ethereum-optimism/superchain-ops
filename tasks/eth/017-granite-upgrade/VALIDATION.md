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

### `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000c307e93a7c530a184c98eade4545a412b857b62f` <br/>
  **After**: `0x000000000000000000000000050ed6f6273c7d836a111e42153bc00d0380b87d` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameImpls(uint32)(address)" 1`. Where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000f691f8a6d908b58c534b624cf16495b491e633ba` <br/>
  **After**: `0x000000000000000000000000a6f3dfdbf4855a43c529bc42ede96797252879af` <br/>
  **Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0x05f9613adb30026ffd634f38e5c4dfd30a197fa1 "gameImpls(uint32)(address)" 0`. Where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).

### `0x18DAc71c228D1C32c99489B7323d441E1175e443` (`AnchorStateRegistryProxy`)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000006b7da1647aa9684f54b2beeb699f91f31cd35fb9` <br/>
  **After**: `0x0000000000000000000000001b5cc028a4276597c607907f24e1ac05d3852cfc` <br/>
  **Meaning**: Updates the eip1967 proxy implementation slot <br/>

- **Key**: `0x2` <br/>
  **Before:** `0x0` <br/>
  **After**: `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` <br/>
  **Meaning**: Sets the superchain config slot value <br/>

### `0x24424336F04440b1c28685a38303aC33C9D14a25` (`LivenessGuard`, Council only)

State Changes:

- **Key:** Compute with `cast index address {yourSignerAddress} 0` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000000000000000000000000000000000006675b61f` <br/>
  **Meaning:** This updates the [`lastLive mapping`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.5.0/packages/contracts-bedrock/src/Safe/LivenessGuard.sol#L36) indicating liveness of an owner that participated in signing. This will be updated to a block timestamp that matches the time when this task was executed. Note that the "before" value may be non-zero for signers that have participated in signing.

### Safe Contract State Changes

The only other state changes should be restricted to one of the following addresses:

- L1 2/2 ProxyAdmin Owner Safe: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
  - The nonce (slot 0x5) should be increased from 5 to 6.
  - Another key is set from 0 to 1 reflecting an entry in the `approvedHashes` mapping.
- Security Council L1 Safe: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
  - The nonce (slot 0x5) should be increased from 6 to 7.
