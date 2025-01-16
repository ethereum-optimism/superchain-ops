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
- Council simulation: `0x7a680028073e956784e910c02dd0a0936604b29cd9f9c71c9d8e568533821e16`
- Foundation simulation: `0xd30a77d4a810ba7768ba1bd52de1cbb869f7b641c57132e46544f044cd7e839a`

calculated as explained in the nested validation doc:
```sh
cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8 # council
# 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
cast index bytes32 0x7b390cc232cd3a45f1100c184953b4e6a6556fe2af978d76b577a87a65345254 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
# 0x7a680028073e956784e910c02dd0a0936604b29cd9f9c71c9d8e568533821e16
```

```sh
cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8 # foundation
# 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
cast index bytes32 0x7b390cc232cd3a45f1100c184953b4e6a6556fe2af978d76b577a87a65345254 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
# 0xd30a77d4a810ba7768ba1bd52de1cbb869f7b641c57132e46544f044cd7e839a
```

## State Changes

### `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (`SystemConfigProxy` for op-sepolia)

* **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
* **Before**: `0x0000000000000000000000000000000000000000000000000000000003938700`
* **After**: `0x00000000000000000000000000000000000d273000001db00000000003938700`
* **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `7600` (`cast td 0x00001db0`) and `862000` (`cast td 0x000d2730`) respectively. These share a slot with the `gasLimit` which remains at `60000000` (`cast td 0x0000000003938700`). See the storage layout snapshot [here.](https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/SystemConfig.json#L58-L78)

### `0x5D63A8Dc2737cE771aa4a6510D063b6Ba2c4f6F2` (`SystemConfigProxy` for metal-sepolia)

* **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
* **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
* **After**: `0x0000000000000000000000000000000000000000000a6fe00000000001c9c380`
* **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `684000` (`cast td 0x000a6fe0`) and `0` respectively. These share a slot with the `gasLimit` which remains at `30000000` (`cast td 0x0000000001c9c380`). See the storage layout snapshot [here.](https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/SystemConfig.json#L58-L78)

and 

* **Key**: `0x0000000000000000000000000000000000000000000000000000000000000066`
* **Before**: `0x00000000000000000000000000000000000000000000000000000000000a6fe0`
* **After**: `0x01000000000000000000000000000000000000000000000000000000000a6fe0`
* **Meaning**: Updates the `scalar` storage variable to reflect a scalar version of `1`. See the storage layout snapshot [here](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.8.0/packages/contracts-bedrock/snapshots/storageLayout/SystemConfig.json#L44-L50).

### `0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2` (`SystemConfigProxy` for mode-sepolia)

* **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
* **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
* **After**: `0x000000000000000000000000000000000008ee87000003d10000000001c9c380`
* **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `977` (`cast td 0x000003d1`) and `585351` (` cast td 0x0008ee87`) respectively. These share a slot with the `gasLimit` which remains at `30000000` (`cast td 0x0000000001c9c380`). See the storage layout snapshot [here.](https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/SystemConfig.json#L58-L78)

### `0xB54c7BFC223058773CF9b739cC5bd4095184Fb08` (`SystemConfigProxy` for zora-sepolia)

* **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
* **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
* **After**: `0x00000000000000000000000000000000000941ad000003f40000000001c9c380`
* **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `1012` (`cast td 0x000003f4`) and `606637` (cast td `0x000941ad`) respectively. These share a slot with the `gasLimit` which remains at `30000000` (`cast td 0x0000000001c9c380`).


### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (`ProxyAdminOwner` for all chains in this task)

* **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005`
* **Before**: `0x0000000000000000000000000000000000000000000000000000000000000010`
* **After**: `0x0000000000000000000000000000000000000000000000000000000000000011`
* **Meaning**: Nonce increments by 1

and

* **Key**: In the [`approvedHashes` section](#nested-safe-state-overrides-and-changes)
* **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
* **After**: `0x0000000000000000000000000000000000000000000000000000000000000001`
* **Meaning**: approvedHashes update. See above.


