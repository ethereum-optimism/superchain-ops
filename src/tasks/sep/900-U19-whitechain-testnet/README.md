# 900-U19-whitechain-testnet

Status: READY TO SIGN

Simulated clean against live Sepolia state on 2026-11-06 at fork block 12078035, exit 0. Hashes,
calldata and the full state diff are in [VALIDATION.md](./VALIDATION.md).

## Objective

Upgrades Whitechain Sepolia (chain id 1874) from `op-contracts/v6.0.0` to `op-contracts/v7.0.0`
(Upgrade 19). One `OPCM.upgradeSuperchain` on the chain's own SuperchainConfig, then one
`OPCM.upgrade`, through the
[OPCM `0x44e197058fb98fb3618453b3d90cdef6f5db8297`](https://sepolia.etherscan.io/address/0x44e197058fb98fb3618453b3d90cdef6f5db8297)
(version 7.1.17, superchain-registry `validation/standard/standard-versions-sepolia.toml`),
executed by the ProxyAdminOwner Safe
[`0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85`](https://sepolia.etherscan.io/address/0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85)
(1-of-1, owner `0xEAd4fe6b892e00763D715095eE4A880637179f3D`, a plain EOA).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| Whitechain Testnet | 1874 | PERMISSIONED (1), **unchanged** | [`0x9328Ea869949f33c57B7b680B6EdB58769e2181c`](https://sepolia.etherscan.io/address/0x9328Ea869949f33c57B7b680B6EdB58769e2181c) |

Whitechain is permissioned-only, runs custom gas token v2, has its own SuperchainConfig and is not
in the superchain-registry, so addresses are read from [addresses.json](./addresses.json). The
upgrade moves SystemConfig to 3.14.2, OptimismPortal2 to 5.6.1, AnchorStateRegistry to 3.9.0,
DisputeGameFactory to 1.6.1, SuperchainConfig to 2.4.2 and the bridges, messenger and factory to
their U19 implementations, and registers the v7 `PermissionedDisputeGame` (2.4.0) for game type 1
with the new MIPS (1.10.1).

`respectedGameType`, the anchor root, `minBaseFee` and the custom-gas-token flag are all left
unchanged. The OPCM reads `isCustomGasToken()` from the chain and never writes it, so no
CGT-specific input exists.

Note the simulation labels the signing Safe `WHITECHAIN_SEPOLIA_Guardian`, because Whitechain's
Guardian and ProxyAdminOwner are the same Safe. That is expected, not a misconfiguration.

## Chain state as of 2026-11-06

| | Value |
|---|---|
| SystemConfig | 3.13.1 (`op-contracts/v6.0.0`) |
| OptimismPortal2 | 5.2.0 |
| AnchorStateRegistry | 3.7.0 |
| DisputeGameFactory | 1.4.0, owner already the PAO Safe |
| SuperchainConfig | 2.4.0 (its own) |
| respectedGameType | 1, `gameImpls(1)` the only registered game |
| isCustomGasToken | true |
| minBaseFee | 5 gwei |
| Portal ETH balance | 0 |
| PAO Safe nonce | 4 |

## Prestate

The type-1 game is registered with the placeholder prestate
`0xdead000000000000000000000000000000000000000000000000000000000000`. A permissioned chain never
loads the CANNON (0) prestate. The value currently on chain is the generic op-program 1.3.1
cannon32 prestate, which has no chain-1874 configuration and does not fit the v7 MIPS64 VM, so it
is not a working prestate either way.

**Do not try to pass this hash to op-challenger.** `--cannon-prestate` takes a *path to a prestate
file*, not a hash (`op-challenger/flags/flags.go:161`: "Path to absolute prestate to use when
generating trace data"), so `--cannon-prestate=0xdead…` is rejected. On a permissioned chain
op-challenger needs no prestate flag at all; see the component section below.

Verified on the replica devnet that this value is never loaded in anger, and that swapping it does
not change the calldata for a disabled game config.

## This upgrade deploys a new DelayedWETH proxy

The single most important thing to carry forward. The U19 OPCM does **not** upgrade the existing
DelayedWETH proxy: it deploys a fresh one and leaves the old `0xDD01A989…e437` unreferenced. The
simulation predicts the new proxy at `0x2e02e6cB6A632ff1c83CC5F3596342299b8117fe`, with
implementation `0xE440CC08…630e` (DelayedWETH 1.5.1), and rewires the DisputeGameFactory game args
for type 1 from the old address to the new one.

**After executing this task, read the new proxy address from the execution state diff and update
`addresses.json` in [sep/901](../901-U20-whitechain-testnet/) and
[sep/902](../902-U21-whitechain-testnet/)**, under all three aliases `DelayedWETHProxy`,
`PermissionedWETH` and `PermissionedDelayedWETHProxy`.

The prediction is likely to hold. On the replica the OPCM's predicted proxy addresses matched the
executed ones twice: the U19 DelayedWETH proxy and the U21 ETHLockbox both landed exactly where the
simulation said. Confirm it anyway from the execution diff or from SystemConfig's `delayedWETH()`,
because signing the next task against a wrong address is the expensive failure, not re-reading one
getter.

Skipping that refresh is how the replica's first U20 simulation failed, with
`MultisigTask: address UNLABELED @<new proxy> not in allowed storage accesses`, which is the tooling
correctly refusing to sign for state the task did not declare.

## Withdrawal and game delays change

The v7 implementations carry the standard delays as constructor immutables, and there are no
setters for them before `op-contracts/v10`.

| Parameter | After |
|---|---|
| `OptimismPortal2.proofMaturityDelaySeconds` | 604800 (7 days) |
| `AnchorStateRegistry.disputeGameFinalityDelaySeconds` | 302400 (3.5 days) |
| `PermissionedDisputeGame.maxClockDuration` | 302400 |
| `DelayedWETH.delay` | 302400 |

A withdrawal proven after the upgrade takes about 7 days to finalize. Withdrawals already proven
against a pre-upgrade game stay valid. Prove one before executing and finalize it after if a
same-day end-to-end check is wanted.

## Off-chain components

The L1 upgrade needs no op-node or op-reth change on a permissioned chain. After execution:

- **op-challenger**: go straight to **v1.11.0**, which also covers U20 and U21 and saves two
  upgrades. On this permissioned chain run it with `--game-types=permissioned`,
  `--cannon-rollup-config`, `--cannon-l2-genesis` and `--cannon-bin`, and **no prestate flag**.
  Do not pass `--cannon-prestate=<hash>`: that flag takes a path to a prestate file and rejects a
  hash. This was hit during the rehearsal.
- **op-proposer**: unchanged, keeps `--game-type=1`.
- **op-dispute-mon**: go straight to **v1.6.4 or newer**, which also covers U20 and U21.

### Karst, U19's other half

The Karst L2 hard fork is independent of this task and can be scheduled before or after it. It
needs `karst_time` in the rollup config for op-node and `karstTime` inside `config` in the L2
genesis for op-reth, **with the same timestamp in both**, or the chain halts on a bad block.
op-node has an `--override.karst` flag; op-reth has no override of any kind, so the genesis edit
cannot be avoided. Minimum versions op-node v1.19.1 and op-reth v2.3.3.

**Karst activation on 1874 is unconfirmed.** Whitechain's public RPC does not whitelist
`eth_config`, so it cannot be read remotely. Ask them directly. For reference, Sepolia activated
Karst at 1781712001 (17 Jun 2026), so a chain following Sepolia defaults would already have it.

## Rehearsed first

The whole sequence was rehearsed on a Whitechain replica devnet (chain id 18740) that mirrors 1874:
same contract versions, custom gas token v2, permissioned-only, its own SuperchainConfig, absent
from the registry. There, U19, Karst and U20 were all executed and U21 simulated clean. The replica
tasks were removed from this branch once ported; their content, hashes and verified state diffs are
in the git history of `sep/901-U19-whitechain-replica`, `sep/902-U20-whitechain-replica` and
`sep/903-U21-whitechain-replica`.

Differences between the replica and Whitechain that matter when comparing diffs:

| | Whitechain (1874) | Replica (18740) |
|---|---|---|
| DisputeGameFactory owner | already the PAO Safe | an EOA, so the replica's diff had a DGF owner write that is **absent here** |
| Guardian | the PAO Safe | an EOA |
| `minBaseFee` | 5 gwei, `storageCodeExceptions` **required** | 0, the exception was a no-op |
| Safe owner | plain EOA | was EIP-7702 delegated, which broke the tooling until revoked |

## Simulation & Signing

Single-safe task (1-of-1 ProxyAdminOwner), no child-safe argument.

```bash
cd src/tasks/sep/900-U19-whitechain-testnet

OP_CI_SEPOLIA_L1_ARCHIVE_RPC_URL=<sepolia archive rpc> SIMULATE_WITHOUT_LEDGER=1 just simulate

USE_KEYSTORE=1 just sign
SIGNATURES=0x... just execute
```

The RPC does **not** need to be an archive node: the fork is near the head, so only recent state
is read. Free load-balanced endpoints answer from backends at different heights and can fail with
`block not found`; if that happens, either use a better endpoint or pin `FORK_BLOCK_NUMBER` a few
blocks back.

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected hashes, the calldata, the decoded state
changes and the post-execution checks.
