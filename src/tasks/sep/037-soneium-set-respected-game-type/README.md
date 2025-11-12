# 037-soneium-set-respected-game-type

Status: [CANCELLED]

This task has been delayed (date TBD).


## Objective

This task sets the respected dispute game type to game type 0 (Permissionless) on Soneium Minato Testnet.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/037-soneium-set-respected-game-type
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate council
```

Signing commands for each safe:
```bash
cd src/tasks/sep/037-soneium-set-respected-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign council
```
