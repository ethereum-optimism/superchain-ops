# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (staging ProxyAdminOwner 157) and move if that
nonce or the calldata changes.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Staging ProxyAdminOwner (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0xae988a64f943bf7f5491bae879bd0f0425e145800465325a76311b5f93bbba67`

Safe transaction hash: `0x81944b7c332f84b0ace01a075e25b2fe4a0a0ffc7ef1d28787f2cff5a4a50ae3`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/125-sepolia-devnet-4-5-opcm-migrate-v900
just simulate-stack sep 125-sepolia-devnet-4-5-opcm-migrate-v900
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the `0x6a761202…` hex the simulation
   prints under "Insert the following hex into the 'Raw input data' field" (the Safe
   `execTransaction`, not the task calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded `migrate` input lists both SystemConfigProxies, `startingRespectedGameType = 9`,
   the prestate `0x03db2e9b…16c9` and the starting anchor root `0xfd29a541…76db` at `1794514637`.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers: the raw
calldata and its breakdown, the expected state changes and the post-execution checks. Signers
only need the two sections above.

### Task Calldata

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000160f0fe4dc1b3f4026687e8dd4b7f800879939cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000304ba55287c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000100fd29a5416d438ba802ab34790e25afd47f55dd02e4b6722f1ade06fe967676db000000000000000000000000000000000000000000000000000000006af61ecd00000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000002000000000000000000000000a15b902f86a60cafe43034eee86a5c19db931e590000000000000000000000001b68cdfdd4ae9985f21033169735e5c4a6200f2c00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000b48bc615daf5e62ea4069adfaba17dc8c766f5110000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000011c37937e08000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002003db2e9bdc15db95cb3a13bb695ae237d7d57dec409120e6e25a76e3873f16c900000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3` from the staging ProxyAdminOwner
(selector `0x82ad56cb`) with **1** delegatecall to the OPCM
`0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc` (`allowFailure = false`):
`migrate((address[],(bool,uint256,uint32,bytes)[],(bytes32,uint256),uint32))`, selector `0xba55287c`.

| Field | Value |
|---|---|
| `chainSystemConfigs` | `0xa15b902f86a60cafe43034eee86a5c19db931e59` (sepolia-devnet-4), `0x1B68cDfDD4aE9985F21033169735e5C4A6200f2C` (sepolia-devnet-5), ascending chain ID |
| `disputeGameConfigs[0]` | SUPER_PERMISSIONED (5), enabled, bond 0, args = proposer `0xb48bc615daf5e62ea4069adfaba17dc8c766f511` (sepolia-devnet-4's proposer) |
| `disputeGameConfigs[1]` | SUPER_CANNON_KONA (9), enabled, bond 0.08 ETH, args = prestate `0x03db2e9bdc15db95cb3a13bb695ae237d7d57dec409120e6e25a76e3873f16c9` (see below) |
| `startingAnchorRoot` | `0xfd29a5416d438ba802ab34790e25afd47f55dd02e4b6722f1ade06fe967676db` @ `1794514637` (2026-11-12 20:17:17 UTC) |
| `startingRespectedGameType` | 9 (SUPER_CANNON_KONA), unchanged from today on both chains |

The shared game takes one proposer, so sepolia-devnet-5's op-proposer
(`0xefa9a82fa18c54abfc6ce92c7c1706b0be8610a4`) must be stopped or repointed after migration.

`cannonKonaPrestate` is a `cannon64-kona-interop` prestate (`kona-client-int`) that embeds sepolia-devnet-4
and -5 as one dependency set `{420130019, 420130020}`, with `lagoon_time = 1794603601` for both. It is built
from `kona-node/v1.11.0-rc.1` (the devnets' kona-program pin) with the kona registry snapshot re-synced
(`KONA_SYNC_SUPERCHAIN=true`) from the superchain-registry commit that makes the pair one dependency set
(superchain-registry#1411), because the tag embeds each chain with a self-only depset and no Lagoon time.
Reproduce with `cd rust && just build-kona-reproducible-prestate` and check
`jq -r .pre kona/prestate-artifacts-cannon-interop/prestate-proof.json`.

The starting anchor root is the two-chain super root
`keccak256(0x01 ‖ be64(ts) ‖ be256(420130019) ‖ outputRoot₄ ‖ be256(420130020) ‖ outputRoot₅)`
at `ts = 1794514637`, from sepolia-devnet-4 block 421196 (output
`0xb5914792…aa76`) and sepolia-devnet-5 block 740249 (output `0xabae0485…4362`), with
`outputRoot = keccak256(bytes32(0) ‖ stateRoot ‖ withdrawalsRoot ‖ blockHash)`. Recompute it with:

```bash
go run ./op-chain-ops/cmd/check-super-root --timestamp 1794514637 \
  --rpc-endpoints https://sepolia-devnet-4.optimism.io/rpc,https://sepolia-devnet-5.optimism.io/rpc
```

To decode the calldata:

```bash
cast calldata-decode "aggregate3((address,bool,bytes)[])" <task calldata>
cast calldata-decode "migrate((address[],(bool,uint256,uint32,bytes)[],(bytes32,uint256),uint32))" <0xba55287c… payload>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
cast call 0xe934Dc97E347C6aCef74364B50125bb8689c40ff "nonce()(uint256)" -r $RPC   # 157
```

```bash
cd src/tasks/sep/125-sepolia-devnet-4-5-opcm-migrate-v900

SIGNATURES=0x... just execute
```

### Task State Changes

`migrate` creates exactly three contracts (the shared `ETHLockbox`, `DisputeGameFactory` and
`AnchorStateRegistry` proxies), all administered by sepolia-devnet-4's ProxyAdmin
`0x3e2455d615f654505978cbe70e3562123f40e922`. Expected contracts in the Tenderly state diff:

| Contract | sepolia-devnet-4 | sepolia-devnet-5 | Change |
|---|---|---|---|
| SystemConfigProxy | `0xa15b902f86a60cafe43034eee86a5c19db931e59` | `0x1b68cdfdd4ae9985f21033169735e5c4a6200f2c` | INTEROP feature enabled |
| OptimismPortalProxy | `0x9ca37b2e7c76509363b9b487e80cfde6b34c730f` | `0x688a54b8735bcad8fa16898e9d19f9795490994d` | `anchorStateRegistry` and `ethLockbox` point at the shared contracts |
| EthLockboxProxy (legacy) | `0xb28bd487cdb130e8d9e3b4ec4067ea100b2b3d6a` | `0x4a3641df76d47a6573732bc98bfafb7f4dc97274` | ETH balance moved to the shared lockbox |
| DisputeGameFactoryProxy (legacy) | `0x2d232e4b21447abfd47c8edfa30700a9bffde1c4` | `0x200f546563cc5ca1fd81f4f220f753d301b256db` | storage writes from `migrate` |
| AnchorStateRegistryProxy (legacy) | `0x2c17231b9248b68fdcdba81b4e0b97cbcf78b089` | `0x350ef62eb34b15a06dabb17d614169bd15235834` | storage writes from `migrate` |
| DelayedWETH | `0x13340f75b4f6f836028c930a3e6c44560c9bdfe6` | `0x04f7a5f42927b32d7d43df4d7b047ae4616c9269` | storage writes from `migrate` |

Plus the three new shared proxies and the staging ProxyAdminOwner nonce (157 → 158). The
template's post-execution checks run the OPCM migration validator and the per-chain standard
validator; the accepted findings are `MIG-SLOCKBOX-40,MIG-CHAIN-0-130,MIG-CHAIN-1-130` for the
migration and `OVERRIDES-L1PAOMULTISIG,SYSCON-130` per chain (staging PAO Safe, devnet
SuperchainConfig).

### Post-execution checks

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
for p in 0x9ca37b2e7c76509363b9b487e80cfde6b34c730f 0x688a54b8735bcad8fa16898e9d19f9795490994d; do
  cast call $p "anchorStateRegistry()(address)" -r $RPC   # same shared ASR on both
  cast call $p "ethLockbox()(address)" -r $RPC            # same shared lockbox on both
done
```
