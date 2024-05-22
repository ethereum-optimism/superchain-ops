# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xb41890910b05dCba3d3dEF19B27E886C4Ab406EB` (The 1 of 1 `ProxyAdmin` owner Safe on L2)

Links:
- [Etherscan](https://sepolia-optimism.etherscan.io/address/0xb41890910b05dCba3d3dEF19B27E886C4Ab406EB)

Enables the simulation by setting the threshold to 1 (threshold was already 1 for this testnet safe):

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

**Notes:**
- Check the provided links to ensure that the correct contract is described at the correct address. 

### `0x4200000000000000000000000000000000000018` (`ProxyAdmin`)

Links:
- [Etherscan](https://sepolia-optimism.etherscan.io/address/0x4200000000000000000000000000000000000018)
- [Optimism Github Repository](https://github.com/ethereum-optimism/optimism/blob/bcdf96abe62da2caaacb0d9571518a7b6c872a37/op-service/predeploys/addresses.go#L23)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x000000000000000000000000b41890910b05dcba3d3def19b27e886c4ab406eb` <br/>
  **After:** `0x0000000000000000000000002fc3ffc903729a0f03966b917003800b145f67f3` <br/>
  **Meaning:** The `_owner` address variable is set to `0x2FC3ffc903729a0f03966b917003800B145F67F3`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/snapshots/storageLayout/ProxyAdmin.json#L4). The current owner of the `ProxyAdmin` contract is `0xb41890910b05dcba3d3def19b27e886c4ab406eb`, which is a 1-of-1 Safe deployed to closely mirror the production environment configuration. The new `_owner` is `0x2FC3ffc903729a0f03966b917003800B145F67F3` which is the aliased L1 Proxy Admin Owner address i.e. 
   ```
   0x1Eb2fFc903729a0F03966B917003800b145F56E2 + 0x1111000000000000000000000000000000001111 = 0x2FC3ffc903729a0f03966b917003800B145F67F3
   ```
   You can check it yourself using this code deployed onchain: [applyL1ToL2Alias](https://sepolia.etherscan.io/address/0xDB893121a8CF3ae4c6fa2fbdcE37691BdA92a838#readContract#F1).

### `0xb41890910b05dcba3d3def19b27e886c4ab406eb` (`L2 Proxy Admin Owner (Safe)`)

Links:
- [Etherscan](https://sepolia-optimism.etherscan.io/address/0xb41890910b05dCba3d3dEF19B27E886C4Ab406EB)
- [Optimism Github Repository](https://github.com/ethereum-optimism/optimism/blob/bcdf96abe62da2caaacb0d9571518a7b6c872a37/op-service/predeploys/addresses.go#L23)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** The Safe nonce is updated.

### `0xfd1d2e729ae8eee2e146c033bf4400fe75284301` (Signer on the L2 Proxy Admin Owner Safe)

State Changes:
- **Nonce** <br/>
  **Before:**: 5 <br/>
  **After:**: 6 <br/>
  **Meaning:** Account sending the transaction and is the only signer on the safe.
