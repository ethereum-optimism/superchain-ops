# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

Note: The changes listed below do not include safe nonce updates or liveness guard related changes.

### `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d` (`DisputeGameFactoryProxy`)

- **Key**: `0x6f48904484b35701cf1f41ad9068b394adf7e2f8a59d2309a04d10a155eaa72b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000011c37937e080000` <br/>
  **Meanning**: Updates the `FaultDisputeGame` initial bond amount to 0.08 ETH. Verify that the slot is correct using `cast index uint 0 102`. Where `0` is the game type and 102 is the [storage slot](https://github.com/ethereum-optimism/optimism/blob/33f06d2d5e4034125df02264a5ffe84571bd0359/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L48).

- **Key**: `0xe34b8b74e1cdcaa1b90aa77af7dd89e496ad9a4ae4a4d4759712101c7da2dce6` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000011c37937e080000` <br/>
  **Meanning**: Updates the `PermissionedDisputeGame` initial bond amount to 0.08 ETH. Verify that the slot is correct using `cast index uint 1 102`. Where `1` is the game type and 102 is the [storage slot](https://github.com/ethereum-optimism/optimism/blob/33f06d2d5e4034125df02264a5ffe84571bd0359/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L48).
