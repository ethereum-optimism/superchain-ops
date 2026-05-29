# 054-U19-ink-metal-mode-zora

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Ink (chainId `57073`), Metal L2 (chainId `1750`), Mode (chainId `34443`),
and Zora (chainId `7777777`) to Upgrade 19 (`op-contracts/v7.1.17`) via
`OPCM.upgradeSuperchain` + `OPCM.upgrade`.

All four chains share the Mainnet L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`)
and are bundled in a single transaction. If simulation shows gas usage exceeds
the 16,777,216 per-transaction cap, this task must be split into two:
`054-U19-ink-metal` and `055-U19-mode-zora` (renumbering downstream tasks).

Executes after `053-U19-op` in the upgrade sequence.

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 054-U19-ink-metal-mode-zora

# Sign
USE_KEYSTORE=1 just sign-stack eth 054-U19-ink-metal-mode-zora

# Execute
cd src/tasks/eth/054-U19-ink-metal-mode-zora
SIGNATURES=0x just execute
```
