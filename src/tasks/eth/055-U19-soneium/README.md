# 055-U19-soneium

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Soneium (chainId `1868`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

Kept as a separate task from the main Group 1 bundle (`054`) following U18
precedent (`042-U18-soneium`).

Executes after `054-U19-ink-metal-mode-zora` in the upgrade sequence.

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 055-U19-soneium

# Sign
USE_KEYSTORE=1 just sign-stack eth 055-U19-soneium

# Execute
cd src/tasks/eth/055-U19-soneium
SIGNATURES=0x just execute
```
