# 044-U17-zora

Status: [READY TO SIGN]

## Objective

This task upgrades Zora Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/044-U17-zora
just simulate-stack sep 044-U17-zora <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/044-U17-zora

just --dotenv-path $(pwd)/.env sign <council|foundation>
```
