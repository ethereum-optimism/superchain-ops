# 090-U19-zora

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Zora Sepolia Testnet (chainId `999999999`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

## Simulation & Signing

```bash
just simulate-stack sep 090-U19-zora
USE_KEYSTORE=1 just sign-stack sep 090-U19-zora
```
