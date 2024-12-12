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

### `0xde744491BcF6b2DD2F32146364Ea1487D75E2509` (`AnchorStateRegistryProxy`)

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x5220f9c5ebf08e84847d542576a67a3077b6fa496235d93c557d5bd5286b431a` <br/>
  **Meaning**: Set the anchor state output root for game type 0 to 0x5220f9c5ebf08e84847d542576a67a3077b6fa496235d93c557d5bd5286b431a. Use the following command to verify: 
  
  ```
  cast rpc --rpc-url $OP_NODE_RPC "optimism_outputAtBlock" $(cast th 523052)
  ```

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb4a`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x000000000000000000000000000000000000000000000000000000000007fb2c`<br/>
  **Meaning**: Set the anchor state L2 block number for game type 0 to 523052.

### `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000a8e6a9bf1ba2df76c6787eaebe2273ae98498059` <br/>
  **After**: `0x0000000000000000000000000A780bE3eB21117b1bBCD74cf5D7624A3a482963` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the new implementation is set using
  `cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameImpls(uint32)(address)" 1`.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000006A8eFcba5642EB15D743CBB29545BdC44D5Ad8cD` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the new implementation is set using
  `cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameImpls(uint32)(address)" 0`.
