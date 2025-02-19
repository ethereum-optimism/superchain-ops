# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000006a8efcba5642eb15d743cbb29545bdc44d5ad8cd` <br/>
  **After**: `0x000000000000000000000000e09185bbb538d084209ef6f1a92dc499d313ce51` <br/>
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000006a8efcba5642eb15d743cbb29545bdc44d5ad8cd`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x0000000000000000000000000a780be3eb21117b1bbcd74cf5d7624a3a482963` <br/>
  **After**: `0x000000000000000000000000f75da262a580cf9b2eab9847559c5837381ae3a3` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000000a780be3eb21117b1bbcd74cf5d7624a3a482963`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.
