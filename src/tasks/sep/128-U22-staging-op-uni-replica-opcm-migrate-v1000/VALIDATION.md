# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (staging ProxyAdminOwner 160) and move if that
nonce or the calldata changes.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Staging ProxyAdminOwner (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0xd58a4ba5b2f475bd76e610ae8b8ba5c9fd94b339e2b4780cdd993babebe50635`

Safe transaction hash: `0xa43c65dee86fed84641262f7bc54814dd3f5410cc48d26d8babe4c89585905ec`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/128-U22-staging-op-uni-replica-opcm-migrate-v1000
just simulate-stack sep 128-U22-staging-op-uni-replica-opcm-migrate-v1000
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the `0x6a761202…` hex the simulation
   prints under "Insert the following hex into the 'Raw input data' field" (the Safe
   `execTransaction`, not the task calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded `migrate` input lists both SystemConfigProxies, game 5 with proposer `0x0595c28b…d8Ba`,
   game 9 with prestate `0x034589…d93d` and a 0.08 ETH bond, the starting anchor root
   `0xa35b1bd1…4082` at `1795608000` and `startingRespectedGameType = 9`.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers: the raw
calldata and its breakdown, the pre-execution checks and execution commands, the expected
state changes and the post-execution checks. Signers only need the two sections above.

### Task Calldata

```
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000091c167c7afbd0d0acc0aa7e4525e90b5cccb76a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000304ba55287c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000100a35b1bd1d9ed7d4ac558e3398ec8e12f7daf548a5282d066afbb176ece7c4082000000000000000000000000000000000000000000000000000000006b06cdc0000000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000020000000000000000000000002fb895799975c47285f950171dabaa873b1587930000000000000000000000004c10de2c774c6b5b8c512f691058fac6dacff728000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000595c28b885f65ce70d65e1a1593ac77e1f2d8ba0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000011c37937e080000000000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000020034589520fac03115a1d2f1dc8ae3632c15593d4b084a6bbb985966f20fed93d00000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3` from the staging ProxyAdminOwner
(selector `0x82ad56cb`) with **1** delegatecall to the v10 OPCM
`0x91C167C7AfBd0D0ACc0AA7e4525e90B5CCcb76A7` (`allowFailure = false`):
`migrate((address[],(bool,uint256,uint32,bytes)[],(bytes32,uint256),uint32))`, selector `0xba55287c`.

| Field | Value |
|---|---|
| `chainSystemConfigs` | `0x2fB895799975C47285f950171dABaa873b158793` (op-int-0), `0x4c10De2C774C6b5B8c512f691058FAC6dacFf728` (uni-int-0), ascending chain ID |
| `disputeGameConfigs[0]` | SUPER_PERMISSIONED (5), enabled, bond 0, args = proposer `0x0595c28b885f65Ce70d65e1A1593ac77e1F2d8Ba` (op-int-0's proposer) |
| `disputeGameConfigs[1]` | SUPER_CANNON_KONA (9), enabled, bond 0.08 ETH, args = prestate `0x034589520fac03115a1d2f1dc8ae3632c15593d4b084a6bbb985966f20fed93d` (kona-client v1.10.0-rc.1 `cannon64-kona-interop`) |
| `startingAnchorRoot` | `0xa35b1bd1d9ed7d4ac558e3398ec8e12f7daf548a5282d066afbb176ece7c4082` @ `1795608000` (2026-11-25 12:00:00 UTC) |
| `startingRespectedGameType` | 9 (SUPER_CANNON_KONA), unchanged from today on both chains |

The shared game takes one proposer, so uni-int-0's op-proposer
(`0xf2CB80F7E9C4b2427f3c60b2254af6B8B56122d6`) must be stopped after migration.

The starting anchor root is the two-chain super root
`keccak256(0x01 ‖ be64(ts) ‖ be256(420130023) ‖ outputRoot_op ‖ be256(420130024) ‖ outputRoot_uni)`
at `ts = 1795608000`, from op-int-0 block 286494 (output `0x54e75725…62dd`) and uni-int-0
block 570684 (output `0xf5f15fcc…9a62`), both finalized, with
`outputRoot = keccak256(bytes32(0) ‖ stateRoot ‖ withdrawalsRoot ‖ blockHash)`. Recompute with:

```bash
go run ./op-chain-ops/cmd/check-super-root --timestamp 1795608000 \
  --rpc-endpoints https://op-int-0.optimism.io/rpc,https://uni-int-0.optimism.io/rpc
```

```bash
cast calldata-decode "aggregate3((address,bool,bytes)[])" <task calldata>
cast calldata-decode "migrate((address[],(bool,uint256,uint32,bytes)[],(bytes32,uint256),uint32))" <0xba55287c… payload>
```

### Pre-execution checks and execution

Before executing, confirm the live nonce still matches the pin in
[config.toml](./config.toml); if not, re-simulate and regenerate the hashes:

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
cast call 0xe934Dc97E347C6aCef74364B50125bb8689c40ff "nonce()(uint256)" -r $RPC   # 160
```

Then execute with the collected signature (the safe is 1-of-1; `just execute` refuses to run
without `SIGNATURES`):

```bash
cd src/tasks/sep/128-U22-staging-op-uni-replica-opcm-migrate-v1000

SIGNATURES=0x... just execute
```

### Task State Changes

`migrate` creates three proxies, all administered by op-int-0's ProxyAdmin
`0x3761A2B7fB5Cc6Fce2187Fa9EfFa13857A7BC8db`. Their addresses are not fixed in advance (they differ
between simulation runs), so check them by role in the Tenderly diff:

| New proxy | Address | Implementation | Initialized with |
|---|---|---|---|
| Shared ETHLockbox | new | `0x406948c8…78d1` (2.1.0) | SuperchainConfig `0x289d…1DBb`; both portals and both legacy lockboxes authorized; receives 0.01 ETH |
| Shared DisputeGameFactory | new | `0x72b97171…393b` (1.6.1) | owner staging PAO; game 5 → `0x5C3eb47c…D691` with proposer `0x0595…d8Ba`; game 9 → `0x4deb67df…b7e8` with prestate `0x034589…d93d`, MIPS `0xacc005dc…5cfa`, DelayedWETH `0xe181…4b53`, bond 0.08 ETH |
| Shared AnchorStateRegistry | new | `0xb11be607…4165` (5.1.0) | shared factory, anchor `0xa35b1bd1…4082` @ 1795608000, respected type 9, finality delay 302400 |

op-int-0's DelayedWETH `0xe181e5a4520d69b22d852a200c2a46e73c774b53` becomes the shared
DelayedWETH: uni-int-0's SystemConfig is repointed to it. Existing contracts written:

| Contract | op-int-0 | uni-int-0 | Change |
|---|---|---|---|
| SystemConfigProxy | `0x2fB895799975C47285f950171dABaa873b158793` | `0x4c10De2C774C6b5B8c512f691058FAC6dacFf728` | INTEROP feature enabled; uni-int-0 DelayedWETH `0x7d3d…2d49` → `0xe181…4b53` |
| OptimismPortalProxy | `0x43090F6Cd0d3f7970B35F9348E411474f0E7942d` | `0x4e445a4e2BaEC3F8c0bCef9137ce83797522077F` | `anchorStateRegistry` and `ethLockbox` → the shared contracts |
| ETHLockboxProxy (legacy) | `0x0a33b2AA1d33F5609a63FD6650E59e389bDDD8d5` | `0x0E8f50D884De5C9Efc69c60c832a1Ba479a6BB23` | 0.005 ETH each moved to the shared lockbox |
| DisputeGameFactoryProxy (legacy) | `0xe235da77a0A13C4B47A303898d99B7ba2c3dB09d` | `0x9a13B95E5690c801739EaD84215EDc8dc8B68B38` | games 5 and 9 cleared (implementation, args, bond) |
| AnchorStateRegistryProxy (legacy) | `0x14601589Cc0ECAb20a7E22A8b3A6980BCDD6DD98` | `0xFBfe26a0ED6C840cf920D30D7C915347ccaBb083` | lockbox reference → the shared lockbox |
| DelayedWETH proxy | `0xe181e5a4520d69b22d852a200c2a46e73c774b53` | `0x7d3d047c2395eba8b9d8f86d8266a87d73412d49` | lockbox reference → the shared lockbox |

Plus the staging ProxyAdminOwner nonce (160 → 161). The template's post-execution checks run
the OPCM migration validator and the per-chain standard validator; the accepted findings are
`MIG-SLOCKBOX-40,MIG-CHAIN-0-130,MIG-CHAIN-1-130` for the migration and
`OVERRIDES-L1PAOMULTISIG,SYSCON-130` per chain.

### Post-execution checks

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
for p in 0x43090F6Cd0d3f7970B35F9348E411474f0E7942d 0x4e445a4e2BaEC3F8c0bCef9137ce83797522077F; do
  cast call $p "anchorStateRegistry()(address)" -r $RPC   # same shared ASR on both
  cast call $p "ethLockbox()(address)" -r $RPC            # same shared lockbox on both
done
ASR=$(cast call 0x43090F6Cd0d3f7970B35F9348E411474f0E7942d "anchorStateRegistry()(address)" -r $RPC)
cast call $ASR "respectedGameType()(uint32)" -r $RPC      # 9
cast call $ASR "getAnchorRoot()(bytes32,uint256)" -r $RPC # 0xa35b1bd1…4082, 1795608000
```
