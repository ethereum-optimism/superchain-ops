# 091-U19-soneium-minato

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Soneium Testnet Minato (chainId `1946`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack sep 091-U19-soneium-minato
USE_KEYSTORE=1 just sign-stack sep 091-U19-soneium-minato
```
