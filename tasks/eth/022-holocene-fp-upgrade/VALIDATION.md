# Validation

This document can be used to validate the state diff resulting from the execution of the FP upgrade transactions.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0x4b0e2029dcd9ecf81462422cfbdc991c89aafd2c04dc7d0a9c0482ad1204e619`
- Foundation simulation: `0x993e276bbc9c09c6928f83f443fca001ee72988bd6937b16b8e7eb78226d8a2f`

calculated as explained in the nested validation doc:
```sh
SAFE_HASH=0x064ff964fe4656de1c4100cf7ef28545395db79865eb65e9a082c7e80e1f7b9a # "Nested hash:"
SAFE_ROLE=0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 # Council
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0x4b0e2029dcd9ecf81462422cfbdc991c89aafd2c04dc7d0a9c0482ad1204e619

SAFE_ROLE=0x847B5c174615B1B7fDF770882256e2D3E95b9D92 # Foundation
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0x993e276bbc9c09c6928f83f443fca001ee72988bd6937b16b8e7eb78226d8a2f
```
## State Overrides

### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation `GnosisSafeProxy`)

Only during foundation simulation.

We're overriding the nonce to increment the current value `10` by `1` to account for task 021, an
upgrade of the `ProtocolVersions`, which has the Foundation Upgrade Safe as the owner.
The simulation will also print out
```
Overriding nonce for safe 0x847B5c174615B1B7fDF770882256e2D3E95b9D92: 10 -> 11
```
And the state changes then show that this nonce is increased from 11 to 12 during the simulation.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005`
  **Value:** `0x000000000000000000000000000000000000000000000000000000000000000b` (`11`)
  **Meaning:** The Foundation Safe nonce is bumped from 10 to 11.

The other state overrides are explained in the generic nested Safe validation document referred to
above.

## State Changes

### `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000a6f3dfdbf4855a43c529bc42ede96797252879af` <br/>
  **After**: `0x00000000000000000000000027b81db41f586016694632193b99e45b1a27b8f8` <br/>
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x000000000000000000000000a6f3dfdbf4855a43c529bc42ede96797252879af`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000050ed6f6273c7d836a111e42153bc00d0380b87d` <br/>
  **After**: `0x00000000000000000000000091a661891248d8c4916fb4a1508492a5e2cbcb87` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
  Before this task has been executed, you will see that the returned address is `0x000000000000000000000000050ed6f6273c7d836a111e42153bc00d0380b87d`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.
