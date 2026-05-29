# 087-U19-ink-metal-mode-zora

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Ink Sepolia Testnet (chainId `763373`), Metal L2 Testnet (chainId `1740`),
Mode Testnet (chainId `919`), and Zora Sepolia Testnet (chainId `999999999`) to
Upgrade 19 (`op-contracts/v7.1.17`) via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

All four chains share the Sepolia L1PAO (`0x1Eb2fFc903729a0F03966B917003800b145F56E2`)
and are bundled in a single transaction. If simulation shows gas usage exceeds
the 16,777,216 per-transaction cap, this task must be split into two:
`087-U19-ink-metal` and `088-U19-mode-zora` (renumbering downstream tasks).

Executes after `086-U19-op` in the upgrade sequence.

## Simulation & Signing

```bash
# Simulate
just simulate-stack sep 087-U19-ink-metal-mode-zora

# Sign
USE_KEYSTORE=1 just sign-stack sep 087-U19-ink-metal-mode-zora

# Execute
cd src/tasks/sep/087-U19-ink-metal-mode-zora
SIGNATURES=0x just execute
```
