# 031-metal-sep-u13-to-u16a

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xdd494b61fb365aad3a7b4e2bf345e949ba5346cfc3d4f96b073b28a0f6f88106)

## Objective

This task upgrades Metal Sepolia to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/031-metal-sep-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/031-metal-sep-u13-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
