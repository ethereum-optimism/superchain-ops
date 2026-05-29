# 087-U19-ink

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Ink Sepolia Testnet (chainId `763373`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack sep 087-U19-ink
USE_KEYSTORE=1 just sign-stack sep 087-U19-ink
```
