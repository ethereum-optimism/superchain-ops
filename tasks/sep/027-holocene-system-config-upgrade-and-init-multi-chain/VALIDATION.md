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
# 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
cast index bytes32 0x28342fccf7308fc0967d8303fd5289550a30acff2de8754cf384b524ebe9ca0a 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
# 0xa2178e2b0ce499a24051659b5ab4528cd4e41b7dff3b76fa6861750f7b154391
```

```sh
cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8 # foundation
# 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
cast index bytes32 0x28342fccf7308fc0967d8303fd5289550a30acff2de8754cf384b524ebe9ca0a 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
# 0x6baf11815ec9e3d4dc6cfa30c0e72dd31a00e45c9ca6d8a40e52f5cc78635009
```

## State Changes

### `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (`SystemConfigProxy` for op-sepolia)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000003938700`
  **After**: `0xx00000000000000000000000000000000000d273000001db00000000003938700`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `7600` and `86200` respectively. These share a slot with the `gasLimit` which remains at `60000000`

### `0x5D63A8Dc2737cE771aa4a6510D063b6Ba2c4f6F2` (`SystemConfigProxy` for metal-sepolia)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
  **After**: `0x0000000000000000000000000000000000000000000a6fe00000000001c9c380`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `68400` and `0` respectively. These share a slot with the `gasLimit` which remains at `30000000`

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000066`
  **Before**: `0x00000000000000000000000000000000000000000000000000000000000a6fe0`
  **After**: `0x01000000000000000000000000000000000000000000000000000000000a6fe0`
  **Meaning**: Updates the `scalar` storage variable to reflect a scalar version of `1`.

### `0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2` (`SystemConfigProxy` for mode-sepolia)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
  **After**: `0x000000000000000000000000000000000008ee87000003d10000000001c9c380`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `977` and `585351` respectively. These share a slot with the `gasLimit` which remains at `30000000`

### `0xB54c7BFC223058773CF9b739cC5bd4095184Fb08` (`SystemConfigProxy` for zora-sepolia)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
  **After**: `0x00000000000000000000000000000000000941ad000003f40000000001c9c380`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `1012` and `606637` respectively. These share a slot with the `gasLimit` which remains at `30000000`


### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (`ProxyAdminOwner` for all chains in this task)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005`
  **Before**: `0x000000000000000000000000000000000000000000000000000000000000000f`
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000010`
  **Meaning**: Nonce increments by 1

- **Key**: See above.
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning**: approvedHashes update. See above.


