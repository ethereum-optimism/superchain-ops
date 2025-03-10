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
> - Message Hash: `0x01282fa031a597c24640050a45eccf82c75916726be89921a9e1717c5868b048`
>
> ### Security Council
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: 
`0x07f0641948ec865a6f115e021adb5972373dc2aa40903746f1ca314a0731c7e6`

## State Overrides

Note: The changes listed below do not include threshold and number of owners overrides or liveness guard related changes, these changes are listed in the [NESTED-VALIDATION.md](../../../NESTED-VALIDATION.md) file.
## State Changes

### `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` (`DisputeGameFactoryProxy`)  

 | **Key** | `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` |
 |---------|----------------------------------------------------------------------------------|
 | **Before** | `0x0000000000000000000000000a780be3eb21117b1bbcd74cf5d7624a3a482963` |
 | **After** | `0x0000000000000000000000008d9faaeb46cbcf487baf2182e438ac3d0847f637` |
 
> [!NOTE]  
> **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31). \
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000000a780be3eb21117b1bbcd74cf5d7624a3a482963`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.



 | **Key** | `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` |
 |---------|----------------------------------------------------------------------------------|
 | **Before** | `0x0000000000000000000000006a8efcba5642eb15d743cbb29545bdc44d5ad8cd` |
 | **After** | `0x0000000000000000000000007e87b471e96b96955044328242456427a0d49694` |

> [!NOTE]  
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000006a8efcba5642eb15d743cbb29545bdc44d5ad8cd`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

### SC Liveness Guard
Liveness Guard related changes are listed [here](../../../NESTED-VALIDATION.md#liveness-guard-security-council-safe-or-unichain-operation-safe-only) file.


## Verify new Absolute Prestate


The following is based on the **op-program/v1.5.0-rc.3**: \
Absolute prestates can be checked in the Superchain Registry [standard-prestates.toml](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml). 

Please, verify that the new absolute prestate is set correctly to `0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9`. \
See [Pectra notice](https://docs.optimism.io/notices/pectra-changes#verify-the-new-absolute-prestate) in docs for more details. \
To manually verify the prestate `0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9`, based on **op-program/v1.5.0-rc.3**, run the below command in the root of https://github.com/ethereum-optimism/optimism/tree/op-program/v1.5.0-rc.3:

You can verify this absolute prestate by running the following [command](https://github.com/ethereum-optimism/optimism/blob/6819d8a4e787df2adcd09305bc3057e2ca4e58d9/Makefile#L133-L135) in the root of the monorepo:

```bash
make reproducible-prestate
```

You should expect the following output at the end of the command:

```bash
Cannon Absolute prestate hash: 
0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
Cannon64 Absolute prestate hash: 
0x039970872142f48b189d18dcbc03a3737338d098b0101713dc2d6710f9deb5ef
CannonInterop Absolute prestate hash: 
0x03a806c966e97816f1ff8d4f04a8ec823099e8f9c32e1d0cfca814f545b85115
```
