# 901-U20-whitechain-testnet

Status: **DRAFT, BLOCKED. NOT READY TO SIGN.**

Blocked on two things: sep/900 (U19) must execute first, and the starting anchor root must be
obtained from Whitechain. See [Before this can be signed](#before-this-can-be-signed).

## Objective

Upgrades Whitechain Sepolia (chain id 1874) from `op-contracts/v7.0.0` to `op-contracts/v8.0.0`
(Upgrade 20). One `OPCM.upgradeSuperchain` on the chain's own SuperchainConfig, then one
`OPCM.upgrade`, through the
[OPCM `0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca`](https://sepolia.etherscan.io/address/0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca)
(version 8.0.1), executed by the ProxyAdminOwner Safe
[`0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85`](https://sepolia.etherscan.io/address/0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85)
(1-of-1, owner `0xEAd4fe6b892e00763D715095eE4A880637179f3D`, a plain EOA).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| Whitechain Testnet | 1874 | PERMISSIONED (1) → **SUPER_PERMISSIONED (5)** | [`0x9328Ea869949f33c57B7b680B6EdB58769e2181c`](https://sepolia.etherscan.io/address/0x9328Ea869949f33c57B7b680B6EdB58769e2181c) |

U20 moves fault proofs from Output Root games to **Super Root** games. Whitechain is
permissioned-only, so it takes the `SUPER_PERMISSIONED` (5) path rather than `SUPER_CANNON_KONA`
(9). The task clears the `CANNON` (0), `PERMISSIONED_CANNON` (1) and `CANNON_KONA` (8)
implementations and their game args, registers `SUPER_PERMISSIONED` with the v8
`SuperPermissionedDisputeGame` (bondless, game args `(AnchorStateRegistry, Proposer)`), rotates
`respectedGameType` from 1 to 5, re-anchors the AnchorStateRegistry to a single-chain super root,
and upgrades SystemConfig to 4.0.0, OptimismPortal2 to 5.8.0 and SuperchainConfig to 2.4.3.

Custom gas token stays enabled. The v8 OPCM reads `isCustomGasToken()` from the chain and only
reverts when an upgrade tries to turn the flag on (`OPContractsManagerV2.sol:997-1003`), so no
CGT-specific input exists.

## Chain state as of 2026-11-06

Read directly from Sepolia. The chain is still on U18, which is why this task is blocked.

| | Value |
|---|---|
| SystemConfig | 3.13.1 (`op-contracts/v6.0.0`) |
| OptimismPortal2 | 5.2.0 |
| AnchorStateRegistry | 3.7.0 |
| DisputeGameFactory | 1.4.0, owner already the PAO Safe |
| SuperchainConfig | 2.4.0 (its own, not the shared one) |
| respectedGameType | 1, with `gameImpls(1)` the only registered game |
| isCustomGasToken | true |
| minBaseFee | 5 gwei |
| Portal ETH balance | 0 |
| PAO Safe nonce | 4 |

## Rehearsed first

This task is a port of a rehearsal that was executed end to end on the Whitechain **replica**
devnet (chain id 18740), which mirrors 1874: same contract versions, custom gas token v2,
permissioned-only, its own SuperchainConfig, absent from the superchain-registry. On the replica,
U19, the Karst L2 fork and U20 were all executed and verified. The replica tasks were removed from
this branch once ported; their full content, hashes and state diffs are in the git history of
`sep/901-U19-whitechain-replica`, `sep/902-U20-whitechain-replica` and
`sep/903-U21-whitechain-replica`.

### Learnings carried over

1. **U19 deploys a new DelayedWETH proxy.** This is the one that bites. The U19 OPCM does not
   upgrade the existing proxy, it deploys a fresh one and leaves the old unreferenced. On the
   replica the first U20 simulation failed with
   `MultisigTask: address UNLABELED @<new proxy> not in allowed storage accesses`, which is the
   tooling correctly refusing to sign for undeclared state.
   **[addresses.json](./addresses.json) still lists the pre-U19 proxy `0xDD01A989…e437` and must be
   refreshed after U19 executes**, under all three aliases `DelayedWETHProxy`, `PermissionedWETH`
   and `PermissionedDelayedWETHProxy`. Every other address survives U19 unchanged.
2. **The `storageCodeExceptions` entry is genuinely required here**, where on the replica it was a
   no-op. SystemConfig slot `0x6c` packs `superchainConfig` in the low 160 bits with `minBaseFee`
   above it. Whitechain's `minBaseFee` is 5 gwei so the slot reads
   `0x00000000000000012a05f20011854d3146a460d095943c3231f2755ba342426e`, and the code-presence check
   would misread it as an address. The replica's `minBaseFee` is 0, so the entry was harmless there
   and easy to drop by accident when porting. Do not drop it.
3. **The `0xdead` placeholder prestate is correct for a permissioned chain**, and verified inert:
   on the replica, swapping the value produced byte-identical calldata and identical hashes.
4. **The RPC need not be an archive node**, since the fork is near the head. Free load-balanced
   endpoints can fail with `block not found` because they answer from backends at different
   heights; use a better endpoint, or pin `FORK_BLOCK_NUMBER` a few blocks back.
5. **Keep `lib/superchain-registry` in sync** with the gitlink after any rebase
   (`git submodule update --init lib/superchain-registry`), or simulations go false-green.

### Expected differences from the replica

| | Whitechain (1874) | Replica (18740) |
|---|---|---|
| DisputeGameFactory owner before | already the PAO Safe | an EOA, so slot `0x33` appeared in the replica diff and will be **absent here** |
| Guardian | the PAO Safe | an EOA |
| `minBaseFee` | 5 gwei, exception required | 0, exception a no-op |
| Safe owner | plain EOA | was EIP-7702 delegated, which broke the tooling until revoked |

The replica's diff was 6 accounts and 21 slots. Whitechain's should be the same minus the
DisputeGameFactory owner write.

## Before this can be signed

1. **Execute sep/900 (U19).** The chain is on v6 and U20 upgrades from v7.
2. **Refresh [addresses.json](./addresses.json)** with the new DelayedWETH proxy that U19 deploys.
3. **Derive the starting anchor root.** `startingAnchorRootRoot` and
   `startingAnchorRootL2SequenceNumber` are part of the signed calldata and must be a single-chain
   super root at a finalized L2 timestamp. **No op-node access is needed**: Whitechain's public RPC
   `https://rpc.testnet.whitechain.io` serves `eth_getProof`, which is enough, even though it does
   not whitelist `optimism_outputAtBlock` or `superroot_atTimestamp`.

   ```
   stateRoot, blockHash   <- eth_getBlockByNumber
   withdrawalStorageRoot  <- eth_getProof on 0x4200000000000000000000000000000000000016, storageHash
   outputRoot = keccak256( bytes32(0) || stateRoot || withdrawalStorageRoot || blockHash )
   superRoot  = keccak256( 0x01 || uint64(timestamp) || uint256(1874) || outputRoot )
   ```

   The formula was validated against op-node's `optimism_outputAtBlock` on the rehearsal devnet,
   matching exactly, then exercised against Whitechain. Their proof window reaches at least 3000
   blocks back, roughly 50 minutes at 1s block time, comfortably past the finality lag.

   The one thing the public RPC cannot report is the L2 **finalized** head. Pick a conservatively
   old block and have Whitechain confirm it is finalized.
4. **Activate Karst**, which is confirmed **not** active on 1874: the L2 Contract Manager
   predeploy's implementation slot is zero. Derive the anchor from a finalized post-Karst block so
   the ordering matches the rehearsal.
5. **Re-read `expectedValidationErrors`** from the first simulation once U19 has landed.
6. **Generate `VALIDATION.md` and the calldata**, then confirm the Safe transaction hash against
   the live Safe at its then-current nonce.

## Component changes

U20 has **no L2 hard fork** and needs no op-node or op-reth configuration change. The fault-proof
services do need work, because the proposer starts proposing super roots.

- **op-proposer** must be restarted at the cutover or proposals stop, since game type 1 ceases to
  exist. Replace `--rollup-rpc` with `--superroot-rpcs` (`OP_PROPOSER_SUPERROOT_RPCS`) and set
  `OP_PROPOSER_GAME_TYPE=5`. Minimum v1.16.4. The op-node serving that RPC needs `--safedb.path`.
- **op-challenger** minimum v1.9.5, add `--superroot-rpc`. Keep existing game types and do **not**
  add a `super-permissioned` trace type.
- **op-dispute-mon** minimum v1.6.0, add `--superroot-rpc`, keep `--rollup-rpc` while pre-upgrade
  games resolve.
- **op-reth** minimum 2.4.4, **op-node** minimum v1.19.6. Not required to execute the L1 upgrade.
- Withdrawal tooling needs viem 2.51.0 or later for Super Root games.

On the replica the proposer produced its first type-5 game within one proposal interval of the
restart, which is the check that it worked.

## Simulation & Signing

Single-safe task (1-of-1 ProxyAdminOwner), no child-safe argument. **Only valid after U19.**

```bash
cd src/tasks/sep/901-U20-whitechain-testnet
OP_CI_SEPOLIA_L1_ARCHIVE_RPC_URL=<sepolia archive rpc> SIMULATE_WITHOUT_LEDGER=1 just simulate
USE_KEYSTORE=1 just sign
SIGNATURES=0x... just execute
```
