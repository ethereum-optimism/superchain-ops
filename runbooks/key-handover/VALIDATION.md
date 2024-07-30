# Validation

This document can be used to validate the state diff resulting from the execution of Key Handover process. 
This task will transfer the `ProxyAdminOwner` role to a different account. 
On Mainnet, this is the multisig at `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`. 
On Sepolia, this is the multisig at `0x1Eb2fFc903729a0F03966B917003800b145F56E2`.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `REPLACE_WITH_CURRENT_PROXY_ADMIN_OWNER` (The current `ProxyAdmin`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/REPLACE_WITH_CURRENT_PROXY_ADMIN_OWNER)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`


## State Changes

**Notes:**
- Check the provided links to ensure that the correct contract is described at the correct address.

### `REPLACE_WITH_PROXY_ADMIN_ADDRESS` (Mode's `ProxyAdmin`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/REPLACE_WITH_PROXY_ADMIN_ADDRESS)
- [Superchain Registry](REPLACE_WITH_LINK_TO_ADDRESS_IN_REGISTRY)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `REPLACE_WITH_BEFORE_VALUE` <br/>
  **After:** `REPLACE_WITH_AFTER_VALUE` <br/>
  **Meaning:** The `ProxyAdmin` owner has been transfered to be the same as OP Sepolia. The correctness of this slot is attested to in the Optimism monorepo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/e6ef3a900c42c8722e72c2e2314027f85d12ced5/packages/contracts-bedrock/snapshots/storageLayout/ProxyAdmin.json#L3-L8).

### `REPLACE_WITH_OLD_PROXY_ADMIN_OWNER` (The old `ProxyAdmin` owner Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/REPLACE_WITH_OLD_PROXY_ADMIN_OWNER)
- [Superchain Registry](REPLACE_WITH_LINK_TO_ADDRESS_IN_REGISTRY)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `REPLACE_WITH_BEFORE_VALUE`<br/>
  **After:** `REPLACE_WITH_AFTER_VALUE` <br/>
  **Meaning:** The Safe nonce is updated.

The only other state change is a nonce increment of the account being used to simulate the transaction.