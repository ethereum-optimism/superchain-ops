# Validation

This document can be used to validate the state overrides and diffs resulting from the execution of the FP upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0x27f38a0f9fb806fdf71a205880cdcbd83a0bfb9ae1769b6a4aa6545c53fa4527`
- Foundation simulation: `0xf50bc38a52b16adccfd799639dd5bfabf655cb35d68c44864186a208b29b37fb`

calculated as explained in the nested validation doc:
```sh
SAFE_HASH=0x63962452498b3b28f8813e99890a00437a292fea8dca8db1fbb97c417e082879 # "Nested hash:"
SAFE_ROLE=0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 # Council
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0x27f38a0f9fb806fdf71a205880cdcbd83a0bfb9ae1769b6a4aa6545c53fa4527

SAFE_ROLE=0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B # Foundation
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0xf50bc38a52b16adccfd799639dd5bfabf655cb35d68c44864186a208b29b37fb
```

## State Changes

This section describes the specific state changes of this upgrade, not related to the nested Safe state changes.

### `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000924d3d3b3b16e74bab577e50d23b2a38990dd52c` <br/>
  **After**: `0x000000000000000000000000833a817ef459f4ecdb83fc5a4bf04d09a4e83f3f` <br/>
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x924D3d3B3b16E74bAb577e50d23b2a38990dD52C`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000879e899523ba9a4ab212a2d70cf1af73b906cbe5` <br/>
  **After**: `0x000000000000000000000000bbd576128f71186a0f9ae2f2aab4afb4af2dae17` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
  Before this task has been executed, you will see that the returned address is `0x879e899523bA9a4Ab212a2d70cF1af73B906CbE5`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.
