# Validation

This document can be used to validate the state diff resulting from the execution of Key Handover process. This task will transfer the `ProxyAdminOwner` role to a different account. On Mainnet, this is the multisig at `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` (The current `ProxyAdmin` owner Safe for Mode, Metal, and Zora)

Links:
- [Etherscan](https://etherscan.io/address/0x4a4962275DF8C60a80d3a25faEc5AA7De116A746)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`


## State Changes

**Notes:**
- Check the provided links to ensure that the correct contract is described at the correct address.

### `0x37Ff0ae34dadA1A95A4251d10ef7Caa868c7AC99` (Metal's `ProxyAdmin`)

Links:
- [Etherscan](https://etherscan.io/address/0x37Ff0ae34dadA1A95A4251d10ef7Caa868c7AC99)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/metal.toml#L48)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a746` <br/>
  **After:** `0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a` <br/>
  **Meaning:** The `ProxyAdmin` owner has been transferred to be the same as [OP Mainnet](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/op.toml#L33). The correctness of this slot is attested to in the Optimism monorepo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.0.0/packages/contracts-bedrock/.storage-layout#L213).

### `0x470d87b1dae09a454A43D1fD772A561a03276aB7` (Mode's `ProxyAdmin`)

Links:
- [Etherscan](https://etherscan.io/address/0x470d87b1dae09a454A43D1fD772A561a03276aB7)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/mode.toml#L48)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a746` <br/>
  **After:** `0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a` <br/>
  **Meaning:** The `ProxyAdmin` owner has been transfrered to be the same as [OP Mainnet](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/op.toml#L33). The correctness of this slot is attested to in the Optimism monorepo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.0.0/packages/contracts-bedrock/.storage-layout#L213).

### `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` (The old `ProxyAdmin` owner Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x4a4962275DF8C60a80d3a25faEc5AA7De116A746)
- [Superchain Registry - Mode](https://github.com/ethereum-optimism/superchain-registry/blob/0fb0dcbefc50882f1bb02fafcb27f47b463875c9/superchain/configs/sepolia/mode.toml#L44)
- [Superchain Registry - Metal](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/mode.toml#L34)
- [Superchain Registry - Zora](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/zora.toml#L34)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x000000000000000000000000000000000000000000000000000000000000002a`<br/>
  **After:** `0x000000000000000000000000000000000000000000000000000000000000002b` <br/>
  **Meaning:** The Safe nonce is updated.

### `0xD4ef175B9e72cAEe9f1fe7660a6Ec19009903b49` (Zora's `ProxyAdmin`)

Links:
- [Etherscan](https://etherscan.io/address/0xD4ef175B9e72cAEe9f1fe7660a6Ec19009903b49)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/zora.toml#L48)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a746` <br/>
  **After:** `0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a` <br/>
  **Meaning:** The `ProxyAdmin` owner has been transferred to be the same as [OP Mainnet](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/op.toml#L33). The correctness of this slot is attested to in the Optimism monorepo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.0.0/packages/contracts-bedrock/.storage-layout#L213).

The only other state change is a nonce increment of the account being used to simulate the transaction.