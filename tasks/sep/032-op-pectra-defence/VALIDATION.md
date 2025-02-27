# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Optimism Foundation
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x328c221a924983de138c889d46f282a85088a349896b3cca109b69d5632182c1`
>
> ### Security Council
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0xe80b66d7e4042fb82e51d81480a1ad1600dd392a4af9f99842b6e1450047fce0`
- Foundation simulation: `0x63bd348b4f1617eabcac49f67f2f40a9040947fd4dad3f262041c7c65a6efce8`

calculated as explained in the nested validation doc.

Additionally, the nonces [will increment by one](../../../NESTED-VALIDATION.md#nonce-increments).

## State Changes

Note: The changes listed below do not include safe nonce updates or liveness guard related changes. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)

### `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` (`DisputeGameFactoryProxy`)

Click on 'show raw state changes'.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000bbdbdfe37c02439764de0e41c906e4396b5b3914` <br/>
  **After**: `0x0000000000000000000000001c3eb0ebd6195ab587e1ded358a87bdf9b56fe04` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the old implementation is set in this slot using
  `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 1`.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000f3ccf0c4b51d42cfe6073f0278c19a8d1900e856` <br/>
  **After**: `0x000000000000000000000000927248cb1255e0f02413a758899db4aecffaa5fe` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the old implementation is set using
  `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 0`.


## Verifying Dispute Games

The old and new dispute game contracts can be compared with the [comparegames.sh](https://gist.github.com/ajsutton/28be852a36d9d19af16f7c870b267873)
script.

From the tenderly simulation click on 'Run on Fork', then copy and export the RPC url provided.

```
export ETH_RPC_URL=https://rpc.tenderly.co/fork/...
```

The arguments to the script can be taken from the before and after values in the `DisputeGameFactoryProxy` above.

### PermissionedDisputeGame:

The only change seen here is the `absolutePrestate()` as expected.

```shell
$ just --justfile ../../../justfile compare-games 0xbbdbdfe37c02439764de0e41c906e4396b5b3914 0x1c3eb0ebd6195ab587e1ded358a87bdf9b56fe04

Matches version()(string) = "1.3.1"

Mismatch absolutePrestate()(bytes32)
Was: 0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568
Now: 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd

Matches maxGameDepth()(uint256) = 73

Matches splitDepth()(uint256) = 30

Matches maxClockDuration()(uint256) = 302400 [3.024e5]

Matches gameType()(uint32) = 1

Matches l2ChainId()(uint256) = 11155420 [1.115e7]

Matches clockExtension()(uint64) = 10800 [1.08e4]

Matches anchorStateRegistry()(address) = 0x218CD9489199F321E1177b56385d333c5B598629
Matches weth()(address)
Matches vm()(address)
```

### FaultDisputeGame:

The only change seen here is the `absolutePrestate()` as expected.

```shell
$ just --justfile ../../../justfile compare-games 0xf3ccf0c4b51d42cfe6073f0278c19a8d1900e856 0x927248cb1255e0f02413a758899db4aecffaa5fe

Matches version()(string) = "1.3.1"

Mismatch absolutePrestate()(bytes32)
Was: 0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568
Now: 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd

Matches maxGameDepth()(uint256) = 73

Matches splitDepth()(uint256) = 30

Matches maxClockDuration()(uint256) = 302400 [3.024e5]

Matches gameType()(uint32) = 0

Matches l2ChainId()(uint256) = 11155420 [1.115e7]

Matches clockExtension()(uint64) = 10800 [1.08e4]

Matches anchorStateRegistry()(address) = 0x218CD9489199F321E1177b56385d333c5B598629
Matches weth()(address)
Matches vmAn()(address)
```
