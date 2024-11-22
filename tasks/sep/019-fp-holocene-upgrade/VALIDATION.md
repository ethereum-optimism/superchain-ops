# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000d9d616e4a03a8e7cc962396c9f8d4e3d306097d3` <br/>
  **After**: `0x0000000000000000000000005e0877a8f6692ed470013e651c4357d0c4941e6c` <br/>
  **Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 0`. Where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x00000000000000000000000098e3f752c7224f8322afa935a4caec3832bb25c9` <br/>
  **After**: `0x0000000000000000000000004ed046e66c96600dae1a4ec39267bb0ce476e8cc` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 1`. Where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
