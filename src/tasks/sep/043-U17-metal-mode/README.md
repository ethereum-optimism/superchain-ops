# 043-U17-metal-mode

Status: [READY TO SIGN]

## Objective

This task upgrades Metal and Mode Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/043-U17-metal-mode
just simulate-stack sep 043-U17-metal-mode <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/043-U17-metal-mode

just --dotenv-path $(pwd)/.env sign <council|foundation>
```
