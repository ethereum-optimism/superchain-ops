# 041-U17-ink

Status: [READY TO SIGN]

## Objective

This task upgrades Ink Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/041-U17-ink
just simulate-stack sep 041-U17-ink <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/041-U17-ink
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
