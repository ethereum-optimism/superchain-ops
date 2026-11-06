# 902-U21-whitechain-testnet

Status: **DRAFT, BLOCKED. NOT READY TO SIGN.**

Blocked on sep/900 (U19) and sep/901 (U20) executing first, and on confirming that
`op-contracts/v9.0.0` is a final release. See [Before this can be signed](#before-this-can-be-signed).

## Objective

Upgrades Whitechain Sepolia (chain id 1874) from `op-contracts/v8.0.0` to `op-contracts/v9.0.0`
(Upgrade 21). One `OPCM.upgradeSuperchain` on the chain's own SuperchainConfig, then one
`OPCM.upgrade`, through the
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://sepolia.etherscan.io/address/0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc)
(version 9.0.3), executed by the ProxyAdminOwner Safe
[`0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85`](https://sepolia.etherscan.io/address/0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85)
(1-of-1, owner `0xEAd4fe6b892e00763D715095eE4A880637179f3D`, a plain EOA).

| Chain | Chain ID | Respected game type | Anchor |
|---|---|---|---|
| Whitechain Testnet | 1874 | SUPER_PERMISSIONED (5), **unchanged** | unchanged, carried over from U20 |

**Unlike U19 and U20, this task rotates nothing.** There is no anchor-root input in v9: the only
override is `startingRespectedGameType`, and it must *equal* the chain's current respected game
type rather than change it. The upgrade swaps implementations and wires an ETHLockbox. On the
replica the diff was 8 accounts and 17 slots, with no DisputeGameFactory write at all.

Expected implementation moves: SystemConfig to 4.3.0, OptimismPortal2 to 6.1.0,
AnchorStateRegistry to 4.0.0, DelayedWETH to 2.0.0, SuperchainConfig to 2.5.0 and
L1CrossDomainMessenger to 2.13.0, plus a **newly deployed ETHLockbox proxy** at 2.0.0.

## U21 is not time-gated

Worth stating because it is a common misreading. U21 is a **contract-only** upgrade with **no L2
hard fork** and no activation timestamp, confirmed by the notice page: "It has no L2 hardfork, so
there is no activation timestamp to configure." Only U19 (Karst) was a hardfork; 18, 20 and 21 are
contract-only. U21 is already executed on two Sepolia devnets, `sep/122` and `sep/123`, and the v9
OPCM is live.

What gates it is the **upgrade sequence**: the chain must already be on v8. Two checks enforce it,
the template's assertion that `startingRespectedGameType` equals the chain's current respected game
type, and the OPCM's on-chain `isPermittedUpgradeSequence`. Attempted early it fails on the first:

```
OPCMUpgradeV900: startingRespectedGameType must equal the chain's current respected game type
```

## Custom gas token: upgradeable, but never migratable

This is the limit of what these upgrades buy Whitechain, and it is permanent rather than a
sequencing issue.

- **`OPCM.upgrade()`, which this task uses, accepts CGT chains.** The guard fires only when an
  upgrade tries to turn the flag *on* (`OPContractsManagerV2.sol:1005-1006`). An already-CGT chain
  passes straight through and no CGT-specific input exists.
- **`OPCM.migrate()` rejects CGT chains outright.** `OPContractsManagerMigrator.sol:484-486`
  reverts `OPContractsManagerMigrator_CustomGasTokenNotSupported`, stating that it "prevents
  incorrect pooling into shared ETHLockbox".

So Whitechain can take every OPCM upgrade but can **never join an interop set**. That is by design,
since a CGT chain holds no ETH to pool, and it is why the lockbox this task deploys stays empty.
Migration is a separate, later task, not in this repository. The notice agrees that U21 "does not
activate interop" and that the merge runbook is "not yet cleared for production chains".

**Worth deciding explicitly with Whitechain**: taking U21 keeps them on supported contracts, it
does not buy interop.

### The ETHLockbox on a CGT chain

`portal.ethLockbox()` is currently zero and the portal's ETH balance is 0, both confirmed
on-chain. The v9 upgrade deploys a new ETHLockbox proxy and wires it to the portal, but **no ETH
moves**, because a CGT chain keeps custody in the portal and holds none. The template asserts the
outcome rather than listing the new proxy, whose address is not knowable before the upgrade, so the
`EthLockboxProxy` entry is absent from [addresses.json](./addresses.json) by design.

## Prestate: set, but inert

The other U21 tasks all set a real kona prestate, and for their **permissionless** chains that is a
genuine state change, a new `gameArgs` write for `SUPER_CANNON_KONA`. This task makes **no
DisputeGameFactory write at all**.

[config.toml](./config.toml) carries the standard kona-client v1.9.0 `cannon64-kona-interop`
prestate `0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9`, from the registry and
named on the notice page, matching sep/115, sep/122, sep/123 and eth/084. It is never encoded here:
`SUPER_CANNON_KONA` (9) is enabled only when `gameImpls(CANNON_KONA) != 0`, and Whitechain has no
such implementation. Verified on the replica by simulating with `0xdead000…000` instead and getting
byte-identical calldata and identical hashes. The notice agrees: "permissioned chains do not use an
absolute prestate for `SUPER_PERMISSIONED` games."

This changes only if Whitechain ever moves to permissionless proofs, which would need a real
reviewed prestate, custom-built since the chain is not in the registry.

## Rehearsed first

Ported from a rehearsal on the Whitechain **replica** devnet (chain id 18740), where the whole
sequence was carried out: U19, the Karst L2 fork, U20 and **U21 were all executed**. U21's
post-execution state on the replica matched its predicted diff exactly, down to the ETHLockbox
landing at the address the simulation predicted, so the expected diff for this task is verified
rather than merely simulated.

Confirmed on the replica after execution: Safe nonce 3, SystemConfig 4.3.0, OptimismPortal2 6.1.0,
AnchorStateRegistry 4.0.0, DelayedWETH 2.0.0, SuperchainConfig 2.5.0, a new ETHLockbox at 2.0.0 with
a zero balance, `isCustomGasToken` still true, `respectedGameType` still 5, the anchor root
unchanged, and proposals still flowing.

The replica tasks were removed from this branch once ported; their content, hashes and full state
diffs are in the git history of `sep/903-U21-whitechain-replica`.

`sep/123-U21-sepolia-devnet-6` is the other close precedent and is already executed: same shape on
every structural property, custom gas token, permissioned on SUPER_PERMISSIONED (5), its own
SuperchainConfig, absent from the registry, 1-of-1 Safe. Review it alongside this task.

### Learnings carried over

1. **The `storageCodeExceptions` entry is genuinely required here**, where it was a no-op on the
   replica, because Whitechain's `minBaseFee` is 5 gwei rather than 0. Do not drop it when porting.
2. **Refresh [addresses.json](./addresses.json) after U19**, which deploys a new DelayedWETH proxy
   and leaves the old unreferenced. Running against a stale address fails with
   `MultisigTask: address UNLABELED @<new proxy> not in allowed storage accesses`.
3. **Pin `FORK_BLOCK_NUMBER`** if `just simulate` fails with `block not found`; public Sepolia RPCs
   are pruned.
4. On the replica the guessed `expectedValidationErrors`, copied from sep/123, proved correct
   unchanged. Still re-read it from a real simulation rather than trusting that.

## Before this can be signed

1. **Execute sep/900 (U19), then sep/901 (U20)**, in that order.
2. **Refresh [addresses.json](./addresses.json)** with the post-U19 DelayedWETH proxy.
3. **Confirm `op-contracts/v9.0.0` is a final release.** The superchain-registry still lists the
   entry as `["op-contracts/v9.0.0-rc.1"]`, the notice page is marked **provisional** and says
   component versions "will be added when the release candidates are published", and no governance
   proposal is linked. Targets were Sepolia 9 Nov 2026 and mainnet 16 Nov 2026. This is fine for a
   devnet and **blocking for a real chain**.
4. **Re-read `expectedValidationErrors`** from the first simulation after U20 lands.
5. **Generate `VALIDATION.md` and the calldata**, and confirm the Safe transaction hash against the
   live Safe at its then-current nonce.

## Component changes

**No flag changes and no L2 hard fork.** The respected game type does not move, so the proposer
keeps `OP_PROPOSER_GAME_TYPE=5` and `--superroot-rpcs` as U20 left them. op-node, op-reth,
op-batcher, op-proposer and op-dispute-mon have no stated requirement.

**One version requirement**: **op-challenger v1.11.0, before the L1 upgrade.** Existing game types
and prestate URL flags carry over. Two caveats from its release notes: `list-games` and
`list-claims` output fields are renamed, which breaks scripts that parse them, and a non-standard
image needs the `kona-host` path set via `OP_CHALLENGER_CANNON_KONA_SERVER`.

### Pause tooling and monitoring must change

Easy to miss, because it is not a version bump. From U21 the **ETHLockbox becomes the chain's pause
identifier**:

- Guardian pause tooling must pass the ETHLockbox address, read from `ethLockbox()` on the
  OptimismPortal, as the pause identifier. `OptimismPortal.paused()` is still the check to read.
- Monitoring that filters `Paused` / `Unpaused` by the OptimismPortal address must be updated.
- ETH balance monitoring moves from the portal to the ETHLockbox. Moot on a CGT chain, where the
  lockbox stays empty, but it matters generally.

The `ETH_LOCKBOX` feature on SystemConfig **can no longer be disabled** after U21, and the portal,
SystemConfig, AnchorStateRegistry and DelayedWETH all resolve their pause through the lockbox.

### Other behavioural changes

- `OptimismPortal2.finalizeWithdrawalTransaction` can revert with `OptimismPortal_L1CDMCallFailed`.
- `L1CrossDomainMessenger` relay gas constants split into `LOCAL_*` and `REMOTE_*`.
- `OptimismPortal.deleteProvenWithdrawal` is added.

## Simulation & Signing

Single-safe task (1-of-1 ProxyAdminOwner), no child-safe argument. **Only valid after U20.**

```bash
cd src/tasks/sep/902-U21-whitechain-testnet
OP_CI_SEPOLIA_L1_ARCHIVE_RPC_URL=<sepolia archive rpc> SIMULATE_WITHOUT_LEDGER=1 just simulate
USE_KEYSTORE=1 just sign
SIGNATURES=0x... just execute
```
