# Validation

This document can be used to validate the state diff resulting from the execution of Key Handover process. This task will transfer the `ProxyAdminOwner` role to a different account. On Sepolia, this is the multisig at 0x1Eb2fFc903729a0F03966B917003800b145F56E2.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x4d59CccA765E1211Bd32Aa6F2A037fD37E519a25` (The current `ProxyAdmin` owner Safe for Minato)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x4d59CccA765E1211Bd32Aa6F2A037fD37E519a25)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`


## State Changes

**Notes:**
- Check the provided links to ensure that the correct contract is described at the correct address.

### `0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0` (Minato's `ProxyAdmin`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/ba679441140c8d64faccc8999b66707c59bf5654/superchain/configs/sepolia/soneium-minato.toml#L60C17-L60C59)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000004d59ccca765e1211bd32aa6f2a037fd37e519a25` <br/>
  **After:** `0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2` <br/>
  **Meaning:** The `ProxyAdmin` owner has been transferred to be the same as [OP Sepolia](https://github.com/ethereum-optimism/superchain-registry/blob/0fb0dcbefc50882f1bb02fafcb27f47b463875c9/superchain/configs/sepolia/op.toml#L50). The correctness of this slot is attested to in the Optimism monorepo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.0.0/packages/contracts-bedrock/.storage-layout#L213).

The only other state change is a nonce increment of the account being used to simulate the transaction.