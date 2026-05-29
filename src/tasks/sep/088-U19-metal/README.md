# 088-U19-metal

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Metal L2 Testnet (chainId `1740`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack sep 088-U19-metal
USE_KEYSTORE=1 just sign-stack sep 088-U19-metal
```
