# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x2419423C72998eb1c6c15A235de2f112f8E38efF` (`DisputeGameFactoryProxy`)

- **Key**: `0xf08cf23b9096e47c93681aae499ab9bfe983e27d836cc8ef3d90a528deceea0c` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x00000000000000000000000054b3b68310ee7e0fe4e44e9429e5c4dd4e5f6eb7` <br/>
  **Meaning**: Updates the ASTERISC_KONA game type implementation. Verify that the new implementation is set using `cast call 0x2419423C72998eb1c6c15A235de2f112f8E38efF "gameImpls(uint32)(address)" 3`. Where `3` is the `ASTERISC_KONA` game type.

### `0x03b82AE60989863BCEb0BbD442A70568e5AefB85` (`AnchorStateRegistryProxy`)

- **Key**: `0x7dfe757ecd65cbd7922a9c0161e935dd7fdbcc0e999689c7d31633896b1fc60b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x00228e17c7ae1a5eb2c7c80ab533cb6d2db03eee7e49ef21dd30d8a439e4d4b8` <br/>
  **Meaning**: Sets the initial anchor root for the new ASTERISC_KONA game type.

- **Key**: `0x7dfe757ecd65cbd7922a9c0161e935dd7fdbcc0e999689c7d31633896b1fc60c`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x0000000000000000000000000000000000000000000000000000000000cd69d6` <br/>
  **Meaning**: Sets the initial anchor block for the new ASTERISC_KONA game type.
