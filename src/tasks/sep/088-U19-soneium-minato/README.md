# 088-U19-soneium-minato

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Soneium Testnet Minato (chainId `1946`) to Upgrade 19
(`op-contracts/v7.1.17`) via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

Kept as a separate task from the main Group 1 bundle (`087`) following U18
precedent (`058-U18-soneium`). Soneium Minato uses a non-standard challenger
address, producing an `OVERRIDES-CHALLENGER` validation error.

Executes after `087-U19-ink-metal-mode-zora` in the upgrade sequence.

## Simulation & Signing

```bash
# Simulate
just simulate-stack sep 088-U19-soneium-minato

# Sign
USE_KEYSTORE=1 just sign-stack sep 088-U19-soneium-minato

# Execute
cd src/tasks/sep/088-U19-soneium-minato
SIGNATURES=0x just execute
```
