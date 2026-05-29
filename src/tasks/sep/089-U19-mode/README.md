# 089-U19-mode

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Mode Testnet (chainId `919`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack sep 089-U19-mode
USE_KEYSTORE=1 just sign-stack sep 089-U19-mode
```
