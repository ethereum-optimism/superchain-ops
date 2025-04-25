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
- Council simulation: `0xe8f8aa2e65c85624906005cf8077cbc632900bd87fdfb6023df637b4fddfffe3`
- Foundation simulation: `0x0d550ba923712ad13c224c6566f757fbc09207dd05fec85aebd7a66e56e27bd5`

calculated as explained in the nested validation doc.

Additionally, the nonces [will increment by one](../../../NESTED-VALIDATION.md#nonce-increments).

## State Changes

Note: The changes listed below do not include safe nonce updates or liveness guard related changes. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)

### `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x000000000000000000000000833a817ef459f4ecdb83fc5a4bf04d09a4e83f3f` <br/>
  **After**: `0x000000000000000000000000F3CcF0C4b51D42cFe6073F0278c19A8D1900e856` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the new implementation is set using
  `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 0`.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000bbd576128f71186a0f9ae2f2aab4afb4af2dae17` <br/>
  **After**: `0x000000000000000000000000bbDBdfe37C02439764dE0e41C906e4396B5B3914` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the new implementation is set using
  `cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 1`.

## Verifying Dispute Games

The old and new dispute game contracts can be compared with https://gist.github.com/ajsutton/28be852a36d9d19af16f7c870b267873

The previous dispute game implementation can be loaded from the `DisputeGameFactory.gameImpl` function. ie:
```
cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 0
cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 1
```

The second argument is the new deployment which should match the state diff above.

FaultDisputeGame:
```
./temp/compareGames.sh 0x833a817eF459f4eCdB83Fc5A4Bf04d09A4e83f3F 0xF3CcF0C4b51D42cFe6073F0278c19A8D1900e856

Matches version()(string) = "1.3.1"

Mismatch absolutePrestate()(bytes32)
Was: 0x03b7eaa4e3cbce90381921a4b48008f4769871d64f93d113fcadca08ecee503b
Now: 0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568

Matches maxGameDepth()(uint256) = 73

Matches splitDepth()(uint256) = 30

Matches maxClockDuration()(uint256) = 302400 [3.024e5]

Matches gameType()(uint32) = 0

Matches l2ChainId()(uint256) = 11155420 [1.115e7]

Matches clockExtension()(uint64) = 10800 [1.08e4]

Matches anchorStateRegistry()(address) = 0x218CD9489199F321E1177b56385d333c5B598629
Matches weth()(address)
Comparing vm

Mismatch version()(string)
Was: "1.0.0-beta.7"
Now: "1.2.1"
```

PermissionedDisputeGame:
```
./temp/compareGames.sh 0xbBD576128f71186A0f9ae2F2AAb4afb4aF2dae17 0xbbDBdfe37C02439764dE0e41C906e4396B5B3914

Matches version()(string) = "1.3.1"

Mismatch absolutePrestate()(bytes32)
Was: 0x03b7eaa4e3cbce90381921a4b48008f4769871d64f93d113fcadca08ecee503b
Now: 0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568

Matches maxGameDepth()(uint256) = 73

Matches splitDepth()(uint256) = 30

Matches maxClockDuration()(uint256) = 302400 [3.024e5]

Matches gameType()(uint32) = 1

Matches l2ChainId()(uint256) = 11155420 [1.115e7]

Matches clockExtension()(uint64) = 10800 [1.08e4]

Matches anchorStateRegistry()(address) = 0x218CD9489199F321E1177b56385d333c5B598629

Matches proposer()(address) = 0x49277EE36A024120Ee218127354c4a3591dc90A9

Matches challenger()(address) = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301
Matches weth()(address)
Comparing vm

Mismatch version()(string)
Was: "1.0.0-beta.7"
Now: "1.2.1"
```

In both, there are two changes:

* absolutePrestate() changes from `0x03b7eaa4e3cbce90381921a4b48008f4769871d64f93d113fcadca08ecee503b` to `0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568`. 
  These can be verified by comparing to the values in [fetcher.go](https://github.com/ethereum-optimism/optimism/blob/develop/op-program/prestates/fetcher.go).
  The old absolute prestate is the cannon64 variant of the 1.4.0 release, the new one is the governance approved, single-threaded cannon version from the same 1.4.0 release.
* vm - the MIPS.sol version. This reverts from the MIPS64.sol beta version back to the governance approved version 1.2.1 from the contracts/1.8.0 (Holocene) release.
