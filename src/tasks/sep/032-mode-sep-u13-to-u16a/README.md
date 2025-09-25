# 032-mode-sep-u13-to-u16a

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x6d7daa0187cb285247d0ff69d3e3726b1ba5cadea9e36ae7a1767d291f269b15)

## Objective

This task upgrades Mode Sepolia to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/032-mode-sep-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/032-mode-sep-u13-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
