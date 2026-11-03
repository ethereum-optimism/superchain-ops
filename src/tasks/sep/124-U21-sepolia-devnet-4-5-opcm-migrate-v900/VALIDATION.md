# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

> [!NOTE]
> Hashes, calldata and state changes below are TODO until sepolia-devnet-5 is deployed and the
> placeholders in [config.toml](./config.toml) are replaced. Regenerate everything from a
> stacked simulation on task 122 at that point.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (staging ProxyAdminOwner 157) and move only if
that nonce moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Staging ProxyAdminOwner (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `TODO`

Safe transaction hash: `TODO`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/124-U21-sepolia-devnet-4-5-opcm-migrate-v900
just simulate-stack sep 124-U21-sepolia-devnet-4-5-opcm-migrate-v900
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded `migrate` input lists the two SystemConfigs in the order above, the super
   proposer, the super root and timestamp from [config.toml](./config.toml),
   `startingRespectedGameType = 9`, and game configs 5 (proposer, no bond) and 9 (kona interop
   prestate, 0.08 ETH).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers: the raw
calldata and its breakdown, the pre-execution checks and execution commands, the expected
state changes and the post-execution checks. Signers only need the two sections above.

### Task Calldata

```
TODO
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3` from the staging ProxyAdminOwner
(selector `0x82ad56cb`) containing **1** delegatecall to the OPCM
`0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc` with `allowFailure = false`:

| # | Function | Selector | Payload |
|---|---|---|---|
| 1 | `migrate((address[],(bool,uint256,uint32,bytes)[],(bytes32,uint256),uint32))` | `0xba55287c` | both SystemConfigs, two game configs, the super root, game type 9 |

To decode it:

```bash
cast calldata-decode "aggregate3((address,bool,bytes)[])" <task calldata>
cast calldata-decode "migrate((address[],(bool,uint256,uint32,bytes)[],(bytes32,uint256),uint32))" <0xba55287c... payload>
```

### Pre-execution checks and execution

Before executing, confirm task 122 has executed on both chains and the live nonce still matches
the pin in [config.toml](./config.toml); if not, re-simulate and regenerate the hash. Refresh
the super root with `check-super-root` if it is older than the chains' current anchors.

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
cast call 0xe934Dc97E347C6aCef74364B50125bb8689c40ff "nonce()(uint256)" -r $RPC   # 157
cast call 0xa15b902f86a60cafe43034eee86a5c19db931e59 "lastUsedOPCMVersion()(string)" -r $RPC   # 9.0.3
```

Then execute with the collected signature (the safe is 1-of-1; `just execute` refuses to run
without `SIGNATURES`). sep/121 needed `--gas-estimate-multiplier 500` for the equivalent call.

```bash
cd src/tasks/sep/124-U21-sepolia-devnet-4-5-opcm-migrate-v900

SIGNATURES=0x... just execute
```

### Task State Changes

TODO: list every contract in the Tenderly state diff with its changed slots. Expected: three
new proxies (shared ETHLockbox, DisputeGameFactory, AnchorStateRegistry); per chain the
`SystemConfigProxy` (`INTEROP` feature, `delayedWETH` to the shared one), `OptimismPortalProxy`
(`anchorStateRegistry`, `ethLockbox` to the shared ones; balance 0), the chain's old
`ETHLockbox` (balance 0), old `DisputeGameFactoryProxy` (games 5 and 9 cleared), old
`AnchorStateRegistryProxy` and DelayedWETH (re-pointed at the shared lockbox); plus the Safe
nonce.

### Post-execution checks

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
for SC in 0xa15b902f86a60cafe43034eee86a5c19db931e59 <devnet-5 SystemConfigProxy>; do
  P=$(cast call $SC "optimismPortal()(address)" -r $RPC)
  cast call $P "ethLockbox()(address)" -r $RPC             # the same shared lockbox for both
  cast call $P "anchorStateRegistry()(address)" -r $RPC    # the same shared ASR for both
  cast call $P "disputeGameFactory()(address)" -r $RPC     # the same shared DGF for both
done
```

Record the three shared addresses here once executed, then repoint the staging proposer,
challenger and dispute-mon at the shared DisputeGameFactory.
