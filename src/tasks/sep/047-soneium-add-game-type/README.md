# 047-soneium-add-game-type

Status: [READY TO SIGN] 

## Objective

This task adds the dispute game type 0 (Permissionless) to the Dispute Game Factory on Soneium Minato Testnet.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/047-soneium-add-game-type
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/047-soneium-add-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign <council|foundation>
```