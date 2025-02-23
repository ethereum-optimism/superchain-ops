# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0x3394b41f3c05f4c1bb2767a59f18fd9cc4497d7a8781dca9206396044c5d4a80`
- Foundation simulation: `0xfd5f9ae7ec744b3e9bbfd555849eb2f5727c46fe3e5cd532c7e102c0934e99c1`

calculated as explained in the nested validation doc.

Additionally, the nonces [will increment by one](../../../NESTED-VALIDATION.md#nonce-increments).

## State Changes

Note: The changes listed below do not include safe nonce updates or liveness guard related changes. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)

### `0xF1408Ef0c263F8c42CefCc59146f90890615A191` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000c0b6c36e14755296476d5d8343654706fe0978a8` <br/>
  **After**: `0x000000000000000000000000d3f6b7df02d5617c7969c1e7a005170a2633c895` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the old implementation is set in this slot using
  `cast call 0xF1408Ef0c263F8c42CefCc59146f90890615A191 "gameImpls(uint32)(address)" 1`.

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000f7fffcb5cf09f594549d1c71a3e69d4a99e46faa` <br/>
  **After**: `0x0000000000000000000000007552446e13fd845157575480832a1b593ee46105` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the old implementation is set using
  `cast call 0xF1408Ef0c263F8c42CefCc59146f90890615A191 "gameImpls(uint32)(address)" 0`.


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
comparegames.sh 0xc0b6c36e14755296476d5d8343654706fe0978a8 0xd3f6b7df02d5617c7969c1e7a005170a2633c895

Matches version()(string) = "1.3.1"

Mismatch absolutePrestate()(bytes32)
Was: 0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c
Now: 0x03631bf3d25737500a4e483a8fd95656c68a68580d20ba1a5362cd6ba012a435

Matches maxGameDepth()(uint256) = 73

Matches splitDepth()(uint256) = 30

Matches maxClockDuration()(uint256) = 302400 [3.024e5]

Matches gameType()(uint32) = 1

Matches l2ChainId()(uint256) = 420110003 [4.201e8]

Matches clockExtension()(uint64) = 10800 [1.08e4]

Matches anchorStateRegistry()(address) = 0x45b52AFe0b60f5aB1a2657b911b57DE0c42e5E50
Matches weth()(address)
Matches vmAn()(address)
```

### FaultDisputeGame:

There are two changes here:
1. the `absolutePrestate()` as expected.
2. The version. This is because the FDG was manually added to the balrog devnet from `develop`.

```shell
Mismatch version()(string)
Was: "1.4.1"
Now: "1.3.1"

Mismatch absolutePrestate()(bytes32)
Was: 0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c
Now: 0x03631bf3d25737500a4e483a8fd95656c68a68580d20ba1a5362cd6ba012a435

Matches maxGameDepth()(uint256) = 73

Matches splitDepth()(uint256) = 30

Matches maxClockDuration()(uint256) = 302400 [3.024e5]

Matches gameType()(uint32) = 0

Matches l2ChainId()(uint256) = 420110003 [4.201e8]

Matches clockExtension()(uint64) = 10800 [1.08e4]

Matches anchorStateRegistry()(address) = 0x45b52AFe0b60f5aB1a2657b911b57DE0c42e5E50
Matches weth()(address)
Matches vmAn()(address)
```
