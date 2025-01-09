# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0xa2178e2b0ce499a24051659b5ab4528cd4e41b7dff3b76fa6861750f7b154391`
- Foundation simulation: `0x6baf11815ec9e3d4dc6cfa30c0e72dd31a00e45c9ca6d8a40e52f5cc78635009`

calculated as explained in the nested validation doc:
```sh
cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8 # council
# 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
cast index bytes32 $SAFE_HASH 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbdd
# TODO
```

```sh
cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8 # foundation
# 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
cast index bytes32 $SAFE_HASH x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
# TODO
```

## State Changes

### `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (`SystemConfigProxy` for op-mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000003938700`
  **After**: `0xx00000000000000000000000000000000000d273000001db00000000003938700`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `7600` and `86200` respectively. These share a slot with the `gasLimit` which remans at `60000000`

### `0x7BD909970B0EEdcF078De6Aeff23ce571663b8aA` (`SystemConfigProxy` for metal-mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
  **After**: `0x0000000000000000000000000000000000000000000a6fe00000000001c9c380`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `68400` and `0` respectively. These share a slot with the `gasLimit` which remans at `30000000`

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000066`
  **Before**: `0x00000000000000000000000000000000000000000000000000000000000a6fe0`
  **After**: `0x01000000000000000000000000000000000000000000000000000000000a6fe0`
  **Meaning**: Updates the `scalar` storage variable to reflect a scalar version of `1`.

### `0x5e6432F18Bc5d497B1Ab2288a025Fbf9D69E2221` (`SystemConfigProxy` for mode-mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
  **After**: `0x000000000000000000000000000000000008ee87000003d10000000001c9c380`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `977` and `585351` respectively. These share a slot with the `gasLimit` which remans at `30000000`

### `0xA3cAB0126d5F504B071b81a3e8A2BBBF17930d86` (`SystemConfigProxy` for zora-mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
  **After**: `0x00000000000000000000000000000000000941ad000003f40000000001c9c380`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `1012` and `606637` respectively. These share a slot with the `gasLimit` which remans at `30000000`

### `0x34A564BbD863C4bf73Eca711Cf38a77C4Ccbdd6A` (`SystemConfigProxy` for arena-z-mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
  **After**: `0x00000000000000000000000000000000000941ad000003f40000000001c9c380`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `1012` and `606637` respectively. These share a slot with the `gasLimit` which remans at `30000000`


### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (`ProxyAdminOwner` for all chains in this task)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005`
  **Before**: `0x000000000000000000000000000000000000000000000000000000000000000f`
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000010`
  **Meaning**: Nonce increments by 1

- **Key**: See above.
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning**: approvedHashes update. See above.


