# 089-U19-unichain

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Unichain Sepolia Testnet (chainId `1301`) to Upgrade 19
(`op-contracts/v7.1.17`) via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

Unichain uses a separate ProxyAdminOwner (`0xd363339eE47775888Df411A163c586a8BdEA9dbf`)
and is independent from the Sepolia Group 1 tasks (`086`-`088`). Its Safe
nonces are not affected by execution order relative to those tasks.

## Simulation & Signing

```bash
# Simulate
just simulate-stack sep 089-U19-unichain

# Sign
USE_KEYSTORE=1 just sign-stack sep 089-U19-unichain

# Execute
cd src/tasks/sep/089-U19-unichain
SIGNATURES=0x just execute
```
