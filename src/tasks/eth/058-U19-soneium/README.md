# 058-U19-soneium

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades soneium to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack eth 058-U19-soneium
USE_KEYSTORE=1 just sign-stack eth 058-U19-soneium
```
