# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

> [!NOTE]
> Hashes, calldata and state changes below are TODO until sepolia-devnet-5 is deployed and the
> placeholders in [config.toml](./config.toml) and [addresses.json](./addresses.json) are
> replaced. Regenerate everything from a simulation at that point.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (staging ProxyAdminOwner 155) and move only if
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
cd src/tasks/sep/122-U21-sepolia-devnet-4-5-opcm-upgrade-v900
just simulate-stack sep 122-U21-sepolia-devnet-4-5-opcm-upgrade-v900
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded `upgrade` inputs show `startingRespectedGameType = 9` with a prestate for
   sepolia-devnet-2, -4 and -5, `startingRespectedGameType = 5` with game 9 disabled for
   sepolia-devnet-3, and `PermittedProxyDeployment = ETHLockbox` on each.

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
(selector `0x82ad56cb`) containing **5** delegatecalls, all to the OPCM
`0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc` with `allowFailure = false`:

| # | Function | Selector | Payload |
|---|---|---|---|
| 1 | `upgradeSuperchain((address,(string,bytes)[]))` | `0x86fe1c66` | devnet SuperchainConfig `0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb`, no extra instructions |
| 2 | `upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))` | `0x8a847e2e` | sepolia-devnet-2 |
| 3 | `upgrade(...)` | `0x8a847e2e` | sepolia-devnet-3 |
| 4 | `upgrade(...)` | `0x8a847e2e` | sepolia-devnet-4 |
| 5 | `upgrade(...)` | `0x8a847e2e` | sepolia-devnet-5 |

Each `upgrade` call carries the chain's `SystemConfigProxy`, six game configs in the fixed
order 0, 1, 8, 5, 9, 10 and two extra instructions: `overrides.cfg.startingRespectedGameType`
(ABI-encoded `9`, or `5` for sepolia-devnet-3) and `PermittedProxyDeployment` (raw
`ETHLockbox`). Game types 0, 1, 8 and 10 are disabled (`enabled = false`, zero bond, empty
args). Game 5 is enabled with the chain's proposer as its only argument and no bond; game 9 is
enabled with the prestate and a 0.08 ETH bond, except on sepolia-devnet-3 where it is disabled.

| Chain | SystemConfigProxy | Game 5 args (proposer) | Game 9 (prestate), bond |
|---|---|---|---|
| sepolia-devnet-2 | `0x5F91Ea5EEA70E505b457A442Dc7A8e5D9641b937` | `0xc7273748d8fFFccb2E64c547C333f9cCBd2C668d` | `0x03b985…faf59`, 0.08 ETH |
| sepolia-devnet-3 | `0x66dac055c7cD3B3a043760521dCa840cB3E8F3FF` | `0x7824594364cDd4ee178d19894685BbfC1E61604a` | disabled |
| sepolia-devnet-4 | `0xa15b902f86a60cafe43034eee86a5c19db931e59` | `0xb48bc615daf5e62ea4069adfaba17dc8c766f511` | `TODO`, 0.08 ETH |
| sepolia-devnet-5 | `TODO` | `TODO` | `TODO`, 0.08 ETH |

To verify the fingerprint of call 1:

```bash
cast calldata "upgradeSuperchain((address,(string,bytes)[]))" "(0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb,[])"
# Expected: 0x86fe1c660000000000000000000000000000000000000000000000000000000000000020000000000000000000000000289d2a1b1ae6e0470d8b72e53b6e3f485f251dbb00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000
```

To decode the calldata back into the three calls and each `upgrade` input:

```bash
cast calldata-decode "aggregate3((address,bool,bytes)[])" <task calldata>
# then, for each 0x8a847e2e... payload returned above:
cast calldata-decode "upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))" <payload>
```

### Pre-execution checks and execution

Before executing, confirm the live nonce still matches the pin in
[config.toml](./config.toml); if not, re-simulate and regenerate the hash:

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
cast call 0xe934Dc97E347C6aCef74364B50125bb8689c40ff "nonce()(uint256)" -r $RPC   # 155
```

Then execute with the collected signature (the safe is 1-of-1; `just execute` refuses to run
without `SIGNATURES`). Earlier v9 upgrades on Sepolia needed well above forge's local gas
estimate; sep/120 used `--gas-estimate-multiplier 300`.

```bash
cd src/tasks/sep/122-U21-sepolia-devnet-4-5-opcm-upgrade-v900

SIGNATURES=0x... just execute
```

### Task State Changes

TODO: list every contract in the Tenderly state diff with its changed slots. Expected, per
chain: `SystemConfigProxy` (implementation, `ETH_LOCKBOX` feature, `lastUsedOPCMVersion`),
`OptimismPortalProxy` (implementation, `anchorStateRegistry`, `ethLockbox`, ETH balance to 0),
a new `ETHLockbox` proxy (created; receives the portal ETH), `DisputeGameFactoryProxy`
(implementation; game 5 and 9 args and bonds), `AnchorStateRegistryProxy` (implementation,
re-initialized with the carried-forward anchor and respected game type 9),
`L1CrossDomainMessengerProxy`, `L1StandardBridgeProxy`, `L1ERC721BridgeProxy`,
`OptimismMintableERC20FactoryProxy`, `AddressManager`, the DelayedWETH proxy
(implementation), plus the shared `SuperchainConfig` proxy (implementation) and the Safe nonce.

### Post-execution checks

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
OPCM=0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc
for SC in 0xa15b902f86a60cafe43034eee86a5c19db931e59 <devnet-5 SystemConfigProxy>; do
  cast call $SC "lastUsedOPCMVersion()(string)" -r $RPC          # 9.0.3
  cast call $SC "version()(string)" -r $RPC                      # 4.3.0
  P=$(cast call $SC "optimismPortal()(address)" -r $RPC)
  cast call $P "ethLockbox()(address)" -r $RPC                   # non-zero
  cast balance $P -r $RPC                                        # 0
done
cast call 0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb "version()(string)" -r $RPC   # 2.5.0
```
