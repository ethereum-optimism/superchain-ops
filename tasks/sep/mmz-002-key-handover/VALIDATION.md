# Validation

This document can be used to validate the state diff resulting from the execution of Key Handover process. This task will transfer ownership of the `ProxyAdminOwner` role to a different account. For mainnet, this is the 2-of-2 multisig of the Optimism Foundation and Security Council.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD` (The current `ProxyAdmin` owner Safe for Mode, Metal, and Zora)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`


## State Changes

**Notes:**
- Check the provided links to ensure that the correct contract is described at the correct address.

### `0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2` (Zora's `ProxyAdmin`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/0fb0dcbefc50882f1bb02fafcb27f47b463875c9/superchain/configs/sepolia/zora.toml#L43)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x000000000000000000000000e75cd021f520b160bf6b54d472fa15e52afe5add` <br/>
  **After:** `0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2` <br/>
  **Meaning:** The `ProxyAdmin` owner has been transfered to be the same as OP Sepolia. The correctness of this slot is attested to in the Optimism monorepo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/e6ef3a900c42c8722e72c2e2314027f85d12ced5/packages/contracts-bedrock/snapshots/storageLayout/ProxyAdmin.json#L3-L8).

### `0xE7413127F29E050Df65ac3FC9335F85bB10091AE` (Mode's `ProxyAdmin`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xE7413127F29E050Df65ac3FC9335F85bB10091AE)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/0fb0dcbefc50882f1bb02fafcb27f47b463875c9/superchain/configs/sepolia/mode.toml#L43)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x000000000000000000000000e75cd021f520b160bf6b54d472fa15e52afe5add` <br/>
  **After:** `0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2` <br/>
  **Meaning:** The `ProxyAdmin` owner has been transfered to be the same as OP Sepolia. The correctness of this slot is attested to in the Optimism monorepo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/e6ef3a900c42c8722e72c2e2314027f85d12ced5/packages/contracts-bedrock/snapshots/storageLayout/ProxyAdmin.json#L3-L8).

### `0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD` (The old `ProxyAdmin` owner Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD)
- [Superchain Registry - Mode](https://github.com/ethereum-optimism/superchain-registry/blob/0fb0dcbefc50882f1bb02fafcb27f47b463875c9/superchain/configs/sepolia/mode.toml#L44)
- [Superchain Registry - Metal](https://github.com/ethereum-optimism/superchain-registry/blob/0fb0dcbefc50882f1bb02fafcb27f47b463875c9/superchain/configs/sepolia/metal.toml#L39)
- [Superchain Registry - Zora](https://github.com/ethereum-optimism/superchain-registry/blob/0fb0dcbefc50882f1bb02fafcb27f47b463875c9/superchain/configs/sepolia/zora.toml#L44)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000005`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **Meaning:** The Safe nonce is updated.

### `0xF7Bc4b3a78C7Dd8bE9B69B3128EEB0D6776Ce18A` (Metal's `ProxyAdmin`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xF7Bc4b3a78C7Dd8bE9B69B3128EEB0D6776Ce18A)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/0fb0dcbefc50882f1bb02fafcb27f47b463875c9/superchain/configs/sepolia/metal.toml#L38)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x000000000000000000000000e75cd021f520b160bf6b54d472fa15e52afe5add` <br/>
  **After:** `0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2` <br/>
  **Meaning:** The `ProxyAdmin` owner has been transfered to be the same as OP Sepolia. The correctness of this slot is attested to in the Optimism monorepo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/e6ef3a900c42c8722e72c2e2314027f85d12ced5/packages/contracts-bedrock/snapshots/storageLayout/ProxyAdmin.json#L3-L8).

The only other state change is a nonce increment of the account being used to simulate the transaction.