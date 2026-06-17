# 053-U19-op-ink-mmz-soneium

Status: [READY TO SIGN]()

## Objective

Upgrades the OP-governed Mainnet networks to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`, bundled into a single transaction:

- OP Mainnet (chainId `10`)
- Ink (chainId `57073`)
- Metal L2 (chainId `1750`)
- Mode (chainId `34443`)
- Zora (chainId `7777777`)
- Soneium (chainId `1868`)

These six chains share the standard Mainnet ProxyAdminOwner, Security Council,
and Foundation Upgrade Safe, so they upgrade together in one OPCM call
(one nonce consumed per safe). Unichain uses a separate ProxyAdminOwner and is
handled in its own task (`054-U19-unichain`).

U19 installs `CANNON_KONA` (game type 8) as the new primary FPVM, rotates
`AnchorStateRegistry.respectedGameType` to `CANNON_KONA` (8) for permissionless
chains (OP, Ink), and disables the legacy `CANNON` slot
(sets `gameImpls[CANNON] = address(0)`). `PERMISSIONED_CANNON` (1) is rewired
by OPCMv2 as the emergency Guardian fallback. Permissioned chains (Metal,
Mode, Zora, Soneium) keep `respectedGameType = 1` and do not receive a
CANNON_KONA implementation.

Check the Tenderly gas output against the 16,777,216 per-transaction cap before
proceeding.

## Simulation & Signing

This task is signed by the Mainnet ProxyAdminOwner, a nested 2-of-2 of the
Security Council and the Foundation Upgrade Safe. Run the commands once for the
safe you sign for, replacing `<council|foundation>` with `council` or
`foundation`.

`SKIP_DECODE_AND_PRINT=1` skips the slow human-readable state-diff printout
without changing the domain/message hashes you verify or the Tenderly link. It
is set on the sign command below; you can also prefix `simulate-stack` with it
for a faster run (review state changes via the Tenderly link instead).

### For Signers

```bash
# Change directory to the task
cd src/tasks/eth/053-U19-op-ink-mmz-soneium

# Simulate
just simulate-stack eth 053-U19-op-ink-mmz-soneium <council|foundation>

# Sign
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 053-U19-op-ink-mmz-soneium <council|foundation>

# Add USE_KEYSTORE=1 before the command if you are signing with a local keystore
# instead of a connected Ledger, e.g.
#   USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack eth 053-U19-op-ink-mmz-soneium <council|foundation>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the task
cd src/tasks/eth/053-U19-op-ink-mmz-soneium

# Approve once per safe, passing that safe's collected signatures
SIGNATURES=0x... just approve <council|foundation>

# Execute once both safes have approved
just execute

# Add USE_KEYSTORE=1 before the command if you are using a local keystore
# instead of a connected Ledger.
```
