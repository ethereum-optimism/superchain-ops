# 026-metal-main-u13-to-u16a

Status: [EXECUTED](https://etherscan.io/tx/0x9c091d94c0f98efb21730224c89e59e50d344b74e677ee6de2b91d2a16f565d2)

## Objective

This task upgrades Metal Mainnet to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/026-metal-main-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/026-metal-main-u13-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
