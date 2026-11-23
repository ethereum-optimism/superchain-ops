# 900-U21-whitechain-mainnet

Status: READY TO SIGN

Simulated clean against live Ethereum mainnet state on 2026-11-23 at PAO Safe nonce 0. Hashes,
calldata and the full state diff are in [VALIDATION.md](./VALIDATION.md).

## Objective

Upgrades Whitechain Mainnet (chain id 1875) from `op-contracts/v8.0.0` to `op-contracts/v9.0.0`
(Upgrade 21). One `OPCM.upgradeSuperchain` on the chain's own SuperchainConfig, then one
`OPCM.upgrade`, through the
[OPCM `0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f`](https://etherscan.io/address/0x2d91e6F2bcF6CD1df90E1FAF9714E18705EA331f)
(version 9.0.3, the same OPCM eth/084 uses), executed by the ProxyAdminOwner Safe
[`0x568440132075d4E1c3E42111EF561636f4956eAd`](https://etherscan.io/address/0x568440132075d4E1c3E42111EF561636f4956eAd)
(Safe v1.5.0, 3-of-5, all owners plain EOAs).

| Chain | Chain ID | Respected game type | Anchor |
|---|---|---|---|
| Whitechain Mainnet | 1875 | SUPER_PERMISSIONED (5), **unchanged** | unchanged |

**This task rotates nothing.** There is no anchor-root input in v9: the only override is
`startingRespectedGameType`, and it must *equal* the chain's current respected game type rather
than change it. The upgrade swaps implementations and wires an ETHLockbox. The diff is 8 accounts
and 17 slots, with no DisputeGameFactory write at all.

Implementation moves: SystemConfig to 4.3.0, OptimismPortal2 to 6.1.0, AnchorStateRegistry to
4.0.0, DelayedWETH to 2.0.0, SuperchainConfig to 2.5.0 and L1CrossDomainMessenger to 2.13.0, plus a
**newly deployed ETHLockbox proxy** at 2.0.0, predicted at
`0x85f1ce8C641Bdd333bffFe0aC095a3229A9f73f7`. Every implementation address is byte-identical to the
testnet task (deterministic deployments).

## How mainnet differs from the testnet (sep/900–902) sequence

The same upgrade was executed and verified on Whitechain Sepolia on 2026-11-23 in tx
[`0xb8d6155c…8bb6b`](https://sepolia.etherscan.io/tx/0xb8d6155cc51b36020911d04ff59582086003e08c9b7f5bb0b342364af1f8bb6b);
post-execution state matched the predicted diff exactly, including the lockbox landing at the
predicted address. Mainnet is simpler in every way that mattered there:

| | Mainnet (1875) | Testnet (1874) |
|---|---|---|
| Starting point | deployed directly at v8, **only U21 needed** | upgraded v6 → U19 → Karst → U20 → U21 |
| PAO Safe | v1.5.0, 3-of-5, nonce 0, plain EOAs | v1.4.1, 2-of-3, two EIP-7702 owners (needed a local tooling patch) |
| Guardian | its own Safe `0x5918870d…eeE0` (same 5 owners, 3-of-5) | the PAO Safe itself |
| `minBaseFee` in L1 storage | 0 (5 gwei floor is genesis-only), exception a no-op (kept) | 5 gwei in slot `0x6c`, entry required |
| Leftover lockbox | unwired 1.3.1 proxy `0xBEDFe523…097D` from the original deploy, ignored by the OPCM | none |
| SystemConfig `opcm` before | the v8 OPCM `0xc19cbd02…1277` it was deployed with | the v8 upgrade OPCM |

Same on both: custom gas token (lockbox stays empty, chain can never be migrated into an interop
set), permissioned-only on SUPER_PERMISSIONED (5), own SuperchainConfig, absent from the
superchain-registry (addresses come from [addresses.json](./addresses.json), sourced from
`whitechain-labs/whitechain-bootstrap` and cross-checked on-chain 2026-11-23).

## U21 is not time-gated

U21 is a contract-only upgrade with no L2 hard fork and no activation timestamp. What gates it is
the upgrade sequence: the chain must already be on v8, which it has been since deployment. Enforced
twice: the template asserts `startingRespectedGameType` equals the chain's current respected game
type, and the v9 OPCM checks `isPermittedUpgradeSequence` on-chain.

## Chain state as of 2026-11-23

Read directly from Ethereum mainnet.

| | Value |
|---|---|
| SystemConfig | 4.0.0 (`op-contracts/v8.0.0`) |
| OptimismPortal2 | 5.8.0, `ethLockbox()` zero, balance 0 |
| AnchorStateRegistry | 3.9.0, anchor `0x7e4d1d02…ee58` / 1795105285 |
| DisputeGameFactory | 1.6.1, owner the PAO Safe, 57 games, type 5 only |
| SuperchainConfig | 2.4.3 (its own, not the shared one) |
| respectedGameType | 5, `gameImpls(5)` = `0x5C3eb47c…D691` (SuperPermissionedDisputeGame 1.1.0, same address as testnet) |
| isCustomGasToken | true |
| minBaseFee | 0 in L1 storage (the 5 gwei floor is genesis/node-side only) |
| PAO Safe | v1.5.0, 3-of-5, nonce 0, all owners plain EOAs |
| Guardian | separate Safe `0x5918870d…eeE0`, same 5 owners, threshold 3 |
| Proposer / Challenger | `0x077843C5…00d9` / `0x0ad1510D…D264` (from `intent.toml`, proposer confirmed on-chain from game 56) |

## Component changes

**No flag changes and no L2 hard fork.** The respected game type does not move, so the proposer
keeps `OP_PROPOSER_GAME_TYPE=5` and `--superroot-rpcs` as deployed. op-node, op-reth, op-batcher,
op-proposer and op-dispute-mon have no stated requirement.

**One version requirement**: **op-challenger v1.11.0 or later, before the L1 upgrade.** On testnet
Whitechain already ran v1.12.0; confirm the mainnet challenger version with them before signing.

### Pause tooling and monitoring must change after execution

From U21 the **ETHLockbox becomes the chain's pause identifier**:

- Guardian pause tooling must pass the ETHLockbox address, read from `ethLockbox()` on the
  OptimismPortal, as the pause identifier. `OptimismPortal.paused()` is still the check to read.
- Monitoring that filters `Paused` / `Unpaused` by the OptimismPortal address must watch the
  lockbox instead.
- ETH balance monitoring would move portal → lockbox, moot on a CGT chain where both stay empty.

The `ETH_LOCKBOX` feature on SystemConfig **can no longer be disabled** after U21.

## Simulation & Signing

Single-safe task (3-of-5 ProxyAdminOwner), no child-safe argument. If `just simulate` fails with
`block not found`, set `FORK_BLOCK_NUMBER` a few blocks behind the head (public load-balanced
endpoints answer from backends at different heights).

```bash
cd src/tasks/eth/900-U21-whitechain-mainnet
OP_CI_MAINNET_L1_ARCHIVE_RPC_URL=<ethereum mainnet rpc> SIMULATE_WITHOUT_LEDGER=1 just simulate
USE_KEYSTORE=1 just sign
SIGNATURES=0x... just execute
```
