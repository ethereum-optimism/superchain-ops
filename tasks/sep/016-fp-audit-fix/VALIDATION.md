# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x0000000000000000000000004873712bdb5fe5b3487bf0a48fff1cdfba794cfd` <br/>
  **After**: `TODO` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0x05f9613adb30026ffd634f38e5c4dfd30a197fa1 "gameImpls(uint32)(address)" 1`. Where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x00000000000000000000000078f2b801730dbd937fe2e209afb3e1cdf3c460bc` <br/>
  **After**: `TODO` <br/>
  **Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0x05f9613adb30026ffd634f38e5c4dfd30a197fa1 "gameImpls(uint32)(address)" 0`. Where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).

### `0x218CD9489199F321E1177b56385d333c5B598629` (`AnchorStateRegistryProxy`)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000aca73cee920bec914009d196a1e4ebe5f28b1920` <br/>
  **After**: `TODO` <br/>
  **Meaning**: Updates the eip1967 proxy implementation slot <br/>

- **Key**: `0x2` <br/>
  **Before:** `0x0` <br/>
  **After**: `0xC2Be75506d5724086DEB7245bd260Cc9753911Be` <br/>
  **Meaning**: Sets the superchain config slot value <br/>


- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49` <br/>
  **Before:** `0x784a7674dc095e73f55f4b86862fd4c3dd0ee13b9c813de647a0cce365d25211` <br/>
  **After**: `TODO` <br/>
  **Meaning**: Updates the output root anchor state of the CANNON game type <br/>

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb4a` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000f19387` <br/>
  **After**: `TODO` <br/>
  **Meaning**: Updates the block number anchor state of the CANNON game type <br/>

- **Key**: `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
  **Before:** `0x784a7674dc095e73f55f4b86862fd4c3dd0ee13b9c813de647a0cce365d25211` <br/>
  **After**: `TODO` <br/>
  **Meaning**: Updates the output root anchor state of the PERMISSIONED_CANNON game type <br/>

- **Key**: `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b6887930` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000f19387` <br/>
  **After**: `TODO` <br/>
  **Meaning**: Updates the block number anchor state of the PERMISSIONED_CANNON game type <br/>
