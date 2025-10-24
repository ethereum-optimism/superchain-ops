# 038-opcm-upgrade-superchainconfig-v500

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task adds upgrades the shared SuperchainConfig implementation on Sepolia from version 2.3.0 to version 2.4.0 (relative contract release v5.0.0).

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/038-opcm-upgrade-superchainconfig-v500
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/038-opcm-upgrade-superchainconfig-v500
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign <council|foundation>
```