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
> ### Security Council
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x9e9fbcadb7fc77235b206403a2cf97a462cb7e7a1b2f942aea67240b91c00335`
>
> ### Optimism Foundation
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x7533b5a58af6220fc954597eace0dd8e26748b949f055e741834e345ef197dd7`

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0x1f3d94bb2ff59b288e25f3d5156c24a6b75281d29ef15cc370be4dd854bc9d20`
- Foundation simulation: `0x87e4e9370516859a0d997376e8302709dd490c59be62fa78fb0e0e727d510768`

calculated as explained in the nested validation doc.

Additionally, the nonces [will increment by one](../../../NESTED-VALIDATION.md#nonce-increments).

## State Changes

Note: The changes listed below do not include safe nonce updates or liveness guard related changes. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)

### `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` (`DisputeGameFactoryProxy`)

Click on 'show raw state changes'.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x00000000000000000000000091a661891248d8c4916fb4a1508492a5e2cbcb87` <br/>
  **After**:  `0x00000000000000000000000060a9769ac9c216a86214869ea49201ca00ac9d2f` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the old implementation is set in this slot using:
    `cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameImpls(uint32)(address)" 1`.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x00000000000000000000000027b81db41f586016694632193b99e45b1a27b8f8` <br/>
  **After**:  `0x000000000000000000000000ec5431d51716b9edd59482d5f1ea4ffe411c5c04` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the old implementation is set using
    `cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameImpls(uint32)(address)" 0`.

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
$ just --justfile ../../../justfile compare-games 0x91a661891248d8c4916fb4a1508492a5e2cbcb87 0x60a9769ac9c216a86214869ea49201ca00ac9d2f

Matches version()(string) = "1.3.1"

Mismatch absolutePrestate()(bytes32)
Was: 0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568
Now: 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd

Matches maxGameDepth()(uint256) = 73

Matches splitDepth()(uint256) = 30

Matches maxClockDuration()(uint256) = 302400 [3.024e5]

Matches gameType()(uint32) = 1

Matches l2ChainId()(uint256) = 10

Matches clockExtension()(uint64) = 10800 [1.08e4]

Matches anchorStateRegistry()(address) = 0x18DAc71c228D1C32c99489B7323d441E1175e443
Matches weth()(address)
Matches vm()(address)
```

### FaultDisputeGame:

The only change seen here is the `absolutePrestate()` as expected.

```shell
$ just --justfile ../../../justfile compare-games 0x27b81db41f586016694632193b99e45b1a27b8f8 0xec5431d51716b9edd59482d5f1ea4ffe411c5c04

Matches version()(string) = "1.3.1"

Mismatch absolutePrestate()(bytes32)
Was: 0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568
Now: 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd

Matches maxGameDepth()(uint256) = 73

Matches splitDepth()(uint256) = 30

Matches maxClockDuration()(uint256) = 302400 [3.024e5]

Matches gameType()(uint32) = 0

Matches l2ChainId()(uint256) = 10

Matches clockExtension()(uint64) = 10800 [1.08e4]

Matches anchorStateRegistry()(address) = 0x18DAc71c228D1C32c99489B7323d441E1175e443
Matches weth()(address)
Matches vm()(address)
```
