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

## Sequencing and external dependencies

1. This task stacks after the two pending mmzd tasks
   (`105-mmzd-l1-ownership-transfers`, `106-mmzd-l2pao-transfer`); the nonce pins in
   `config.toml` are the post-106 values (live + 2 on the L1PAO, Foundation Upgrade
   Safe and Security Council).
2. Unichain Sepolia's ProxyAdminOwner transfer to the standard L1PAO is executed by the
   current Unichain Safe (`0xd363339eE47775888Df411A163c586a8BdEA9dbf`) outside this
   repo. It shares no signers with the safes above (no nonce impact), but it MUST have
   executed on-chain before this task is signed. Simulation reproduces the
   post-transfer state through state overrides on Unichain's L1 ProxyAdmin and
   DisputeGameFactory owner slots.

BLOCKING before signing: all four `startingAnchorRootRoot` values in `config.toml` are
placeholders (`0xdead...`) and MUST be replaced with each chain's honest super root
(and its timestamp as `startingAnchorRootL2SequenceNumber`), after which the task must
be re-simulated and VALIDATION.md hashes regenerated.

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
