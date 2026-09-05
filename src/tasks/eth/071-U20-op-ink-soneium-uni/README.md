# 071-U20-op-ink-soneium-uni

Status: DRAFT, NOT READY TO SIGN

## Objective

Executes Upgrade 20 (op-contracts/v8.0.0-rc.3) on the four production mainnet chains,
via `OPCM.upgradeSuperchain` + one `OPCM.upgrade` per chain, bundled into a single
transaction from the standard Mainnet L1 ProxyAdminOwner
(`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`, 2-of-2 of the Foundation Upgrade Safe
and the Security Council):

| Chain      | Chain ID | Respected game type after upgrade      |
|------------|----------|----------------------------------------|
| OP Mainnet | 10       | SUPER_CANNON_KONA (9)                  |
| Ink        | 57073    | SUPER_CANNON_KONA (9)                  |
| Soneium    | 1868     | SUPER_PERMISSIONED (5, permissioned-only chain) |
| Unichain   | 130      | SUPER_CANNON_KONA (9)                  |

U20 rotates the proofs foundation from output roots to super roots. On each chain the
upgrade clears the retiring CANNON (0), PERMISSIONED_CANNON (1) and CANNON_KONA (8)
game impls, installs SUPER_PERMISSIONED (5) as the permissioned fallback (proposer-only
args, zero bond), installs SUPER_CANNON_KONA (9) where a CANNON_KONA impl existed to
carry over (OP Mainnet, Ink, Unichain), rotates
`AnchorStateRegistry.respectedGameType`, and re-anchors the AnchorStateRegistry to an
honest super root via the `overrides.cfg.startingAnchorRoot` extra instruction. Soneium
stayed permissioned through U19 and has no CANNON_KONA impl, so it rotates to
SUPER_PERMISSIONED (5) instead.

The OPCM used is the op-contracts/v8.0.0-rc.3 deployment on Mainnet
(`0x1951828ce913dc4383a8a1695695d537a11d896a`, version 8.0.1).

## Sequencing and external dependencies

1. This task stacks after the two pending mmzd tasks (`067-mmzd-l1-ownership-transfers`,
   `068-mmzd-l2pao-transfer`); those consume one nonce each on the L1PAO, Foundation
   Upgrade Safe and Security Council.
2. It also sequences after the Unichain PAO transition (`eth/069`/`eth/070` on `main`,
   DRAFT, gated on the Unichain governance vote). Those tasks execute from the Unichain
   3-of-3 Safe (`0x6d5B183F538ABB8572F5cD17109c617b994D5833`) — no L1PAO nonce impact —
   but the Foundation Upgrade Safe and Security Council are child signers of that
   3-of-3, so each consumes one FUS and one SC nonce. The nonce pins in `config.toml`
   are therefore L1PAO live+2, FUS/SC live+4.
3. `eth/069` MUST have executed on-chain before this task is signed: it transfers
   Unichain's L1 ProxyAdmin and DisputeGameFactory ownership to the standard L1PAO,
   which this task requires. Simulation reproduces the post-069 state via state
   overrides on Unichain's L1 ProxyAdmin and DisputeGameFactory owner slots.

BLOCKING before signing: all four `startingAnchorRootRoot` values in `config.toml` are
placeholders (`0xdead...`) and MUST be replaced with each chain's honest super root
(and its timestamp as `startingAnchorRootL2SequenceNumber`), after which the task must
be re-simulated and VALIDATION.md hashes regenerated.

## Simulation & Signing

```bash
cd src/
just simulate-stack eth 071-U20-op-ink-soneium-uni council
just simulate-stack eth 071-U20-op-ink-soneium-uni foundation
```

Signing:

```bash
USE_KEYSTORE=1 just sign-stack eth 071-U20-op-ink-soneium-uni council
USE_KEYSTORE=1 just sign-stack eth 071-U20-op-ink-soneium-uni foundation
```

Execution, from the task directory:

```bash
cd src/tasks/eth/071-U20-op-ink-soneium-uni
SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```
