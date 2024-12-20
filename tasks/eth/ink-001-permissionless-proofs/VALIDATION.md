# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
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

Note: The changes listed below do not include safe nonce updates or liveness guard related changes.

### `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000a8e6a9bf1ba2df76c6787eaebe2273ae98498059` <br/>
  **After**: `0x0000000000000000000000000A780bE3eB21117b1bBCD74cf5D7624A3a482963` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the slot is correct using `cast index uint 1 101` where 1 is the game type and 101 is the [storage slot](https://github.com/ethereum-optimism/optimism/blob/33f06d2d5e4034125df02264a5ffe84571bd0359/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) of the `gameImpls` mapping.

- **Key**: `0x6f48904484b35701cf1f41ad9068b394adf7e2f8a59d2309a04d10a155eaa72b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000011c37937e080000` <br/>
  **Meanning**: Updates the `FaultDisputeGame` initial bond amount to 0.08 ETH. Verify that the slot is correct using `cast index uint 0 102`. Where `0` is the game type and 102 is the [storage slot](https://github.com/ethereum-optimism/optimism/blob/33f06d2d5e4034125df02264a5ffe84571bd0359/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L48).

- **Key**: `0xe34b8b74e1cdcaa1b90aa77af7dd89e496ad9a4ae4a4d4759712101c7da2dce6` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000011c37937e080000` <br/>
  **Meanning**: Updates the `PermissionedDisputeGame` initial bond amount to 0.08 ETH. Verify that the slot is correct using `cast index uint 1 102`. Where `1` is the game type and 102 is the [storage slot](https://github.com/ethereum-optimism/optimism/blob/33f06d2d5e4034125df02264a5ffe84571bd0359/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L48).

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000006A8eFcba5642EB15D743CBB29545BdC44D5Ad8cD` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the slot is correct using `cast index uint 0 101` where 0 is the game type and 101 is the [storage slot](https://github.com/ethereum-optimism/optimism/blob/33f06d2d5e4034125df02264a5ffe84571bd0359/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) of the `gameImpls` mapping.

### `0xde744491BcF6b2DD2F32146364Ea1487D75E2509` (`AnchorStateRegistryProxy`)

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x5220f9c5ebf08e84847d542576a67a3077b6fa496235d93c557d5bd5286b431a` <br/>
  **Meaning**: Set the anchor state output root for game type 0 to 0x5220f9c5ebf08e84847d542576a67a3077b6fa496235d93c557d5bd5286b431a. This is the slot for the `anchors` mapping, which can be computed as `cast index uint 0 1`, where 0 is the game type and 1 is the slot of the `anchors` mapping. If you have access to the Ink Mainnet's op-node RPC endpoint and want to verify the new root, you can use the following command to verify:
  ```
  cast rpc --rpc-url $OP_NODE_RPC "optimism_outputAtBlock" $(cast th 523052)
  ```

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb4a`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x000000000000000000000000000000000000000000000000000000000007fb2c`<br/>
  **Meaning**: Set the anchor state L2 block number for game type 0 to 523052. The slot number can be calculated using the same approach as above, and incremented by 1, based on the contract storage layout

### Safe Contract State Changes

The only other state changes should be restricted to one of the following addresses:

- L1 2/2 ProxyAdmin Owner Safe: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
  - The nonce (slot 0x5) should be increased from 7 to 8.
  - Another key is set from 0 to 1 reflecting an entry in the `approvedHashes` mapping.
- Security Council L1 Safe: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
  - The nonce (slot 0x5) should be increased from 9 to 10. This only occurs for Council signers.
- Foundation Safe: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
  - The nonce (slot 0x5) should be increased from 12 to 13. This only occurs for Foundation signers.
