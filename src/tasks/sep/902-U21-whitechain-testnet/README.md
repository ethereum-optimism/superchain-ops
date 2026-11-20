# 902-U21-whitechain-testnet

Status: READY TO SIGN

Simulated clean against live Sepolia state on 2026-11-20 at PAO Safe nonce 7, after U20. Hashes,
calldata and the full state diff are in [VALIDATION.md](./VALIDATION.md).

## Objective

Upgrades Whitechain Sepolia (chain id 1874) from `op-contracts/v8.0.0` to `op-contracts/v9.0.0`
(Upgrade 21). One `OPCM.upgradeSuperchain` on the chain's own SuperchainConfig, then one
`OPCM.upgrade`, through the
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://sepolia.etherscan.io/address/0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc)
(version 9.0.3), executed by the ProxyAdminOwner Safe
[`0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85`](https://sepolia.etherscan.io/address/0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85)
(2-of-3; two owners carry an EIP-7702 delegation).

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
3. **The RPC need not be an archive node**, since the fork is near the head. If `just simulate`
   fails with `block not found`, the endpoint is load-balanced across backends at different
   heights; use a better one, or pin `FORK_BLOCK_NUMBER` a few blocks back.
4. On the replica the guessed `expectedValidationErrors`, copied from sep/123, proved correct
   unchanged. Still re-read it from a real simulation rather than trusting that.

## Before this can be signed

All done as of 2026-11-20:

1. U19 (sep/900) and U20 (sep/901) executed; the Safe nonce is 7.
2. [addresses.json](./addresses.json) lists the post-U19 DelayedWETH proxy `0x2e02e6cB…17fe`.
3. `op-contracts/v9.0.0` is final: U21 is executed on mainnet with the same OPCM version, 9.0.3.
4. `expectedValidationErrors` held unchanged in the simulation.

Before executing, the proposer must have created a type-5 game on the U20 contracts, and
op-challenger must be v1.11.0 or newer.

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

Single-safe task (2-of-3 ProxyAdminOwner), no child-safe argument. If `just simulate` fails with
`block not found`, set `FORK_BLOCK_NUMBER` a few blocks behind the head.

```bash
cd src/tasks/sep/902-U21-whitechain-testnet
OP_CI_SEPOLIA_L1_ARCHIVE_RPC_URL=<sepolia archive rpc> SIMULATE_WITHOUT_LEDGER=1 just simulate
USE_KEYSTORE=1 just sign
SIGNATURES=0x... just execute
```
