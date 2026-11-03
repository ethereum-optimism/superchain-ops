# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

> [!NOTE]
> Hashes, calldata and state changes below are TODO until sepolia-devnet-6 is deployed and on
> `op-contracts/v8.0.0`, and the placeholders in [config.toml](./config.toml) and
> [addresses.json](./addresses.json) are replaced. Regenerate everything from a simulation at
> that point.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (staging ProxyAdminOwner 156) and move only if
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
cd src/tasks/sep/123-U21-sepolia-devnet-6-opcm-upgrade-v900
just simulate-stack sep 123-U21-sepolia-devnet-6-opcm-upgrade-v900
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded `upgrade` input shows `startingRespectedGameType = 5`, game 9 disabled, and
   `PermittedProxyDeployment = ETHLockbox`.

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
(selector `0x82ad56cb`) containing **2** delegatecalls, both to the OPCM
`0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc` with `allowFailure = false`:

| # | Function | Selector | Payload |
|---|---|---|---|
| 1 | `upgradeSuperchain((address,(string,bytes)[]))` | `0x86fe1c66` | sepolia-devnet-6's SuperchainConfig `TODO`, no extra instructions |
| 2 | `upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))` | `0x8a847e2e` | sepolia-devnet-6 |

The `upgrade` call carries the chain's `SystemConfigProxy`, six game configs in the fixed
order 0, 1, 8, 5, 9, 10 and two extra instructions: `overrides.cfg.startingRespectedGameType`
(ABI-encoded `5`) and `PermittedProxyDeployment` (raw `ETHLockbox`). Only game 5 is enabled,
with the chain's proposer as its only argument and no bond; 0, 1, 8, 9 and 10 are disabled
(`enabled = false`, zero bond, empty args).

To decode the calldata back into the two calls and the `upgrade` input:

```bash
cast calldata-decode "aggregate3((address,bool,bytes)[])" <task calldata>
cast calldata-decode "upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))" <0x8a847e2e... payload>
```

### Pre-execution checks and execution

Before executing, confirm the live nonce still matches the pin in
[config.toml](./config.toml); if not, re-simulate and regenerate the hash:

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
cast call 0xe934Dc97E347C6aCef74364B50125bb8689c40ff "nonce()(uint256)" -r $RPC   # 156
```

Then execute with the collected signature (the safe is 1-of-1; `just execute` refuses to run
without `SIGNATURES`):

```bash
cd src/tasks/sep/123-U21-sepolia-devnet-6-opcm-upgrade-v900

SIGNATURES=0x... just execute
```

### Task State Changes

TODO: list every contract in the Tenderly state diff with its changed slots. Expected:
`SystemConfigProxy` (implementation, `ETH_LOCKBOX` feature, `lastUsedOPCMVersion`),
`OptimismPortalProxy` (implementation, `anchorStateRegistry`, `ethLockbox`; balance
unchanged), a new `ETHLockbox` proxy (created, empty), `DisputeGameFactoryProxy`
(implementation; game 5 args), `AnchorStateRegistryProxy` (implementation, re-initialized with
the carried-forward anchor and respected game type 5), `L1CrossDomainMessengerProxy`,
`L1StandardBridgeProxy`, `L1ERC721BridgeProxy`, `OptimismMintableERC20FactoryProxy`,
`AddressManager`, the DelayedWETH proxy (implementation), the chain's `SuperchainConfig` proxy
(implementation) and the Safe nonce.

### Post-execution checks

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
SC=<sepolia-devnet-6 SystemConfigProxy>
cast call $SC "lastUsedOPCMVersion()(string)" -r $RPC          # 9.0.3
cast call $SC "isCustomGasToken()(bool)" -r $RPC               # true
P=$(cast call $SC "optimismPortal()(address)" -r $RPC)
cast call $P "ethLockbox()(address)" -r $RPC                   # non-zero
cast call $(cast call $P "anchorStateRegistry()(address)" -r $RPC) "respectedGameType()(uint32)" -r $RPC   # 5
```
