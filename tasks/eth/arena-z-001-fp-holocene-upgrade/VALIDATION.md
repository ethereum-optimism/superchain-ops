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
> - Message Hash: `0x2e656d5acac73781f3bdfc6a4bad3e200b9f3d3e2ec0824a861f4dd13ef49677`
>
> ### Security Council
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: 
`0x1de136dd299af50a049cfcf141295581fae64ee216e9c68c85366b1cd616dbf5`

## State Overrides

Note: The changes listed below do not include threshold and number of owners overrides or liveness guard related changes, these changes are listed in the [NESTED-VALIDATION.md](../../../NESTED-VALIDATION.md) file.
## State Changes

### `0x658656A14AFdf9c507096aC406564497d13EC754` (`DisputeGameFactoryProxy`)  

 | **Key** | `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` |
 |---------|----------------------------------------------------------------------------------|
 | **Before** | `0x000000000000000000000000227882E5972EbAd990dcF04E2dbe2fC84094E146` |
 | **After** | `0x00000000000000000000000080533687a66A1bB366094A9B622873a6CA8415a5` |
 
> [!NOTE]  
> **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x658656A14AFdf9c507096aC406564497d13EC754 "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31). \
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000000227882E5972EbAd990dcF04E2dbe2fC84094E146`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.



 | **Key** | `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` |
 |---------|----------------------------------------------------------------------------------|
 | **Before** | `0x0000000000000000000000000000000000000000000000000000000000000000` |
 | **After** | `0x000000000000000000000000733a80Ce3bAec1f27869b6e4C8bc0E358C121045` |

> [!NOTE]  
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x658656A14AFdf9c507096aC406564497d13EC754 "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000000000000000000000000000000000000000000000`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

### SC Liveness Guard
Liveness Guard related changes are listed [here](../../../NESTED-VALIDATION.md#liveness-guard-security-council-safe-or-unichain-operation-safe-only) file.


## Verify new Absolute Prestate


The following is based on the **op-program/v1.6.0-rc.1**: \
Absolute prestates can be checked in the Superchain Registry [standard-prestates.toml](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml). 

Please, verify that the new absolute prestate is set correctly to `0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9`. \
See [Pectra notice](https://docs.optimism.io/notices/pectra-changes#verify-the-new-absolute-prestate) in docs for more details. \
To manually verify the prestate `0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9`, based on **op-program/v1.6.0-rc.1**, run the below command in the root of https://github.com/ethereum-optimism/optimism/tree/op-program/v1.6.0-rc.1:

You can verify this absolute prestate by running the following [command](https://github.com/ethereum-optimism/optimism/blob/6819d8a4e787df2adcd09305bc3057e2ca4e58d9/Makefile#L133-L135) in the root of the monorepo:

```bash
make reproducible-prestate
```

You should expect the following output at the end of the command:

```bash
Cannon Absolute prestate hash: 
0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9
Cannon64 Absolute prestate hash: 
0x03394563dd4a36e95e6d51ce7267ecceeb05fad23e68d2f9eed1affa73e5641a
CannonInterop Absolute prestate hash: 
0x03ada038f8a81526c68596586dfc762eb5412d4d5bb7cb46110d8c47ee570d7e
```
