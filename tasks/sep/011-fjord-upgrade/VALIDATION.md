# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

The only pertinent state changes (ignoring safe nonce updates) should be made to the `DisputeGameFactoryProxy` game type implementations.

### `0x05f9613adb30026ffd634f38e5c4dfd30a197fa1` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  **Before**: `0x000000000000000000000000bea4384facbcf51279962fbcfb8f16f9ed2fe0c6`
  **After**: `0x000000000000000000000000848e6ff026a56e75a1137f89f6286d14789997bc`
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0x05f9613adb30026ffd634f38e5c4dfd30a197fa1 gameImpls(uint32)(address) 1`.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  **Before**: `0x000000000000000000000000d5bc8c45692aada756f2d68f0a2002d6bf130c42`
  **After**: `0x0000000000000000000000003bc41c5206df07c842a850818ffb94796d42313d`
  **Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0x05f9613adb30026ffd634f38e5c4dfd30a197fa1 gameImpls(uint32)(address) 0`.
