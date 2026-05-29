# 056-U19-mode

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades mode to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack eth 056-U19-mode
USE_KEYSTORE=1 just sign-stack eth 056-U19-mode
```
