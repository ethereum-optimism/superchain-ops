# 057-U19-zora

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades zora to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack eth 057-U19-zora
USE_KEYSTORE=1 just sign-stack eth 057-U19-zora
```
