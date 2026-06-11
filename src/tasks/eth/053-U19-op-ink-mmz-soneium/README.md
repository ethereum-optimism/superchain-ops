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

```bash
# Simulate
just simulate-stack eth 053-U19-op-ink-mmz-soneium

# Sign
USE_KEYSTORE=1 just sign-stack eth 053-U19-op-ink-mmz-soneium

# Execute
cd src/tasks/eth/053-U19-op-ink-mmz-soneium
SIGNATURES=0x just execute
```
