# 099-U19-op-ink-mmz-soneium

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades the OP-governed Sepolia networks to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`, bundled into a single transaction:

- OP Sepolia Testnet (chainId `11155420`)
- Ink Sepolia Testnet (chainId `763373`)
- Metal L2 Testnet (chainId `1740`)
- Mode Testnet (chainId `919`)
- Zora Sepolia Testnet (chainId `999999999`)
- Soneium Testnet Minato (chainId `1946`)

These six chains share the standard Sepolia ProxyAdminOwner, Security Council,
and Foundation Upgrade Safe, so they upgrade together in one OPCM call
(one nonce consumed per safe). Unichain uses a separate ProxyAdminOwner and is
handled in its own task (`100-U19-unichain`).

U19 installs `CANNON_KONA` (game type 8) as the new primary FPVM, rotates
`AnchorStateRegistry.respectedGameType` to `CANNON_KONA` (8), and disables
the legacy `CANNON` slot (sets `gameImpls[CANNON] = address(0)`).
`PERMISSIONED_CANNON` (1) is rewired by OPCMv2 as the emergency Guardian fallback.

Check the Tenderly gas output against the 16,777,216 per-transaction cap before
proceeding.

## Simulation & Signing

```bash
# Simulate
just simulate-stack sep 099-U19-op-ink-mmz-soneium

# Sign
USE_KEYSTORE=1 just sign-stack sep 099-U19-op-ink-mmz-soneium

# Execute
cd src/tasks/sep/099-U19-op-ink-mmz-soneium
SIGNATURES=0x just execute
```
