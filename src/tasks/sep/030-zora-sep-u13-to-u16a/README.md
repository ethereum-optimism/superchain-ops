# 030-zora-sep-u13-to-u16a

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xb000e85475326c5278204d31492945e4100f2c747f19e91b53ceb6a5e620ad6e)

## Objective

This task upgrades Zora Sepolia to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/030-zora-sep-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/030-zora-sep-u13-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
