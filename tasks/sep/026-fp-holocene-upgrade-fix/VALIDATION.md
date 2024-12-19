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
- Council simulation: `0x1188ef4fb2355c49d442a7f950dad4492a2961a34786ce407c3db8c8d331250d`
- Foundation simulation: `0x030c89f6f0b759d892697ad05de88183a3f6f579e0abe30c81427eaefb20a459`

calculated as explained in the nested validation doc:
```sh
SAFE_HASH=0x572c29de03270811431295a31c25273c7dbf3bc0f17f29a8fe3131f86b7a9cb6 # "Nested hash:"
SAFE_ROLE=0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 # Council
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0x1188ef4fb2355c49d442a7f950dad4492a2961a34786ce407c3db8c8d331250d

SAFE_ROLE=0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B # Foundation
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0x030c89f6f0b759d892697ad05de88183a3f6f579e0abe30c81427eaefb20a459
```

## State Changes

This section describes the specific state changes of this upgrade, not related to the nested Safe state changes.

### `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000005e0877a8f6692ed470013e651c4357d0c4941e6c` <br/>
  **After**: `0x000000000000000000000000e591ebbc2ba0ead3db6a0867cc132fe1c123f448` <br/>
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000005e0877a8f6692ed470013e651c4357d0c4941e6c`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x0000000000000000000000004ed046e66c96600dae1a4ec39267bb0ce476e8cc` <br/>
  **After**: `0x000000000000000000000000b51bad2d9da9f94d6a4a5a493ae6469005611b68` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000004ed046e66c96600dae1a4ec39267bb0ce476e8cc`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.
