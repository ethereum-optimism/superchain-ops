# 042-U17-arena-z

Status: [READY TO SIGN]

## Objective

This task upgrades Arena-Z Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/042-U17-arena-z
just simulate-stack sep 042-U17-arena-z <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/042-U17-arena-z
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
