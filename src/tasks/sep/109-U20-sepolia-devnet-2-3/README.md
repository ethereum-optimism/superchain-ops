# 109-U20-sepolia-devnet-2-3

Status: DRAFT, NOT READY TO SIGN

## Objective

Executes Upgrade 20 (op-contracts/v8.0.0-rc.3) on the two OP Labs Sepolia devnets, via
`OPCM.upgradeSuperchain` + one `OPCM.upgrade` per chain, bundled into a single
transaction from the shared devnet ProxyAdminOwner Safe
(`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`, 1-of-1):

| Chain            | Chain ID  | Respected game type after upgrade |
|------------------|-----------|-----------------------------------|
| sepolia-devnet-2 | 420130015 | SUPER_CANNON_KONA (9)             |
| sepolia-devnet-3 | 420130018 | SUPER_PERMISSIONED (5)            |

U20 rotates the proofs foundation from output roots to super roots. On each chain the
upgrade clears the retiring CANNON (0), PERMISSIONED_CANNON (1) and CANNON_KONA (8)
game impls, installs SUPER_PERMISSIONED (5) as the permissioned fallback (proposer-only
args, zero bond), installs SUPER_CANNON_KONA (9) where a CANNON_KONA impl existed to
carry over (devnet-2 only), rotates `AnchorStateRegistry.respectedGameType`, and
re-anchors the AnchorStateRegistry to an honest super root via the
`overrides.cfg.startingAnchorRoot` extra instruction.

The OPCM used is the op-contracts/v8.0.0-rc.3 deployment on Sepolia
(`0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca`, version 8.0.1).

The SUPER_CANNON_KONA game installed on sepolia-devnet-2 uses the kona-client/v1.7.0-rc.2
`cannon64-kona-interop` prestate
(`0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`, from the
superchain-registry `validation/standard/standard-prestates.toml`). sepolia-devnet-2 is
embedded in that kona release's registry snapshot; sepolia-devnet-3 is not, but it
installs no SUPER_CANNON_KONA game, so the prestate is never encoded for it.

The `startingAnchorRootRoot` / `startingAnchorRootL2SequenceNumber` values in `config.toml`
are single-chain super roots at a recently finalized L2 block of each chain (derived on
2026-09-08 with `op-chain-ops/cmd/check-super-root`, see the per-chain comments). They MUST
be re-derived from a trusted node close to signing and the task re-simulated.

This task is intended to be executed from this PR branch (the V800 template stack),
not from `main`.

## Simulation & Signing

```bash
cd src/
just simulate-stack sep 109-U20-sepolia-devnet-2-3
```

Signing (the devnet PAO is a 1-of-1 Safe):

```bash
USE_KEYSTORE=1 just sign-stack sep 109-U20-sepolia-devnet-2-3
```

Execution, from the task directory:

```bash
cd src/tasks/sep/109-U20-sepolia-devnet-2-3
SIGNATURES=0x... just execute
```
