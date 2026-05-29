# 055-U19-metal

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades metal to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack eth 055-U19-metal
USE_KEYSTORE=1 just sign-stack eth 055-U19-metal
```
