# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Optimism Foundation
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xd6cf200b33a74be6c4b3c4d9325ae97560a4aa9e93c7c16cf9765dc558ce9d5f`
>
> ### Security Council
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: 
`0x9608627ac1f7ff7f50b47a695e9a4b70120d72d4b9f184e742ec0ddf01fc41f3`

## State Overrides

Note: The changes listed below do not include threshold and number of owners overrides or liveness guard related changes, these changes are listed in the [NESTED-VALIDATION.md](../../../NESTED-VALIDATION.md) file.
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
### SC Liveness Guard

Liveness Guard related changes are listed [here](../../../NESTED-VALIDATION.md#liveness-guard-security-council-safe-or-unichain-operation-safe-only) file.


## Verify new Absolute Prestate

The following is based on the **op-program/v1.5.0-rc.2**: \
Absolute prestates can be checked in the Superchain Registry [standard-prestates.toml](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml). \
Please verify that the new absolute prestate is set correctly to `0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd`. \
See [Pectra notice](https://docs.optimism.io/notices/pectra-changes#verify-the-new-absolute-prestate) in docs for more details. \
To manually verify the prestate `0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd`, based on **op-program/v1.5.0-rc.2**, run the below command in the root of https://github.com/ethereum-optimism/optimism/tree/op-program/v1.5.0-rc.2: \
You can verify this absolute prestate by running the following [command](https://github.com/ethereum-optimism/optimism/blob/6819d8a4e787df2adcd09305bc3057e2ca4e58d9/Makefile#L133-L135) in the root of the monorepo:

```bash
make reproducible-prestate
```

You should expect the following output at the end of the command:

```bash
Cannon Absolute prestate hash:
0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd
Cannon64 Absolute prestate hash:
0x03a7d967025dc434a9ca65154acdb88a7b658147b9b049f0b2f5ecfb9179b0fe
CannonInterop Absolute prestate hash:
0x0379d61de1833af6766f07b4ed931d85b3f6282508bbcbf9f4637398d97b61c1
```
