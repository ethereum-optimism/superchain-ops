# 056-U19-unichain

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Unichain (chainId `130`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

Unichain uses a separate ProxyAdminOwner (`0x6d5B183F538ABB8572F5cD17109c617b994D5833`)
and Unichain Operations Safe (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`).
The Foundation Upgrade Safe and Security Council are also signers in the
Unichain governance flow. FUS and SC nonces assume tasks `053`, `054`, and `055`
have all been executed first.

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 056-U19-unichain

# Sign
USE_KEYSTORE=1 just sign-stack eth 056-U19-unichain

# Execute
cd src/tasks/eth/056-U19-unichain
SIGNATURES=0x just execute
```
