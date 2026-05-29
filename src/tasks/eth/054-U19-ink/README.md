# 054-U19-ink

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades ink to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack eth 054-U19-ink
USE_KEYSTORE=1 just sign-stack eth 054-U19-ink
```
