# 110-U20-op-ink-soneium-uni

Status: DRAFT, NOT READY TO SIGN

## Objective

Executes Upgrade 20 (op-contracts/v8.0.0-rc.3) on the four production Sepolia chains,
via `OPCM.upgradeSuperchain` + one `OPCM.upgrade` per chain, bundled into a single
transaction from the standard OP-governed Sepolia L1 ProxyAdminOwner
(`0x1Eb2fFc903729a0F03966B917003800b145F56E2`, 2-of-2 of the Foundation Upgrade Safe
and the Security Council):

| Chain                  | Chain ID | Respected game type after upgrade |
|------------------------|----------|-----------------------------------|
| OP Sepolia Testnet     | 11155420 | SUPER_CANNON_KONA (9)             |
| Ink Sepolia            | 763373   | SUPER_CANNON_KONA (9)             |
| Soneium Testnet Minato | 1946     | SUPER_CANNON_KONA (9)             |
| Unichain Sepolia       | 1301     | SUPER_CANNON_KONA (9)             |

U20 rotates the proofs foundation from output roots to super roots. On each chain the
upgrade clears the retiring CANNON (0), PERMISSIONED_CANNON (1) and CANNON_KONA (8)
game impls, installs SUPER_PERMISSIONED (5) as the permissioned fallback (proposer-only
args, zero bond), installs SUPER_CANNON_KONA (9) carrying over each chain's existing
CANNON_KONA setup, rotates `AnchorStateRegistry.respectedGameType` to 9, and re-anchors
the AnchorStateRegistry to an honest super root via the
`overrides.cfg.startingAnchorRoot` extra instruction.

The OPCM used is the op-contracts/v8.0.0-rc.3 deployment on Sepolia
(`0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca`, version 8.0.1).

Every SUPER_CANNON_KONA game is installed with the kona-client/v1.7.0-rc.2
`cannon64-kona-interop` prestate
(`0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`, from the
superchain-registry `validation/standard/standard-prestates.toml`).

## Sequencing and external dependencies

1. The two mmzd tasks (`105-mmzd-l1-ownership-transfers`, `106-mmzd-l2pao-transfer`)
   have executed and no other pending Sepolia task signs from these safes, so the nonce
   pins in `config.toml` are the live values of the L1PAO, Foundation Upgrade Safe and
   Security Council.
2. Unichain Sepolia's ProxyAdminOwner transfer to the standard L1PAO is executed by the
   current Unichain Safe (`0xd363339eE47775888Df411A163c586a8BdEA9dbf`) outside this
   repo. It shares no signers with the safes above (no nonce impact), but it MUST have
   executed on-chain before this task is signed. Simulation reproduces the
   post-transfer state through state overrides on Unichain's L1 ProxyAdmin and
   DisputeGameFactory owner slots.

The `startingAnchorRootRoot` / `startingAnchorRootL2SequenceNumber` values in `config.toml`
are single-chain super roots at a recently finalized L2 block of each chain (derived on
2026-09-08 with `op-chain-ops/cmd/check-super-root`, see the per-chain comments). They are
part of the signed calldata, so they are fixed once the calldata is published; verify them
against a trusted node (`check-super-root --timestamp <recorded timestamp>`) before signing.

## Simulation & Signing

```bash
cd src/
just simulate-stack sep 110-U20-op-ink-soneium-uni council
just simulate-stack sep 110-U20-op-ink-soneium-uni foundation
```

Signing:

```bash
USE_KEYSTORE=1 just sign-stack sep 110-U20-op-ink-soneium-uni council
USE_KEYSTORE=1 just sign-stack sep 110-U20-op-ink-soneium-uni foundation
```

Execution, from the task directory:

```bash
cd src/tasks/sep/110-U20-op-ink-soneium-uni
SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```
