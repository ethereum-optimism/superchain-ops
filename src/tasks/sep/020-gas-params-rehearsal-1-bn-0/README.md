# 020-gas-params-rehearsal-1-bn-0: Testing task against a devnet with local addresses.json

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x226dcb3fd84115a0fd4e8762bb9f916e6bc6229e801ac9cbf0ec3d83353443c9)

## Objective

Testing task against a devnet with local addresses.json. This will send no-op txs to the SystemConfig contract, which will ensure the process works without making any configuration changes.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/020-gas-params-rehearsal-1-bn-0
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```

Signing commands for each safe:
```bash
cd src/tasks/sep/020-gas-params-rehearsal-1-bn-0
just --dotenv-path $(pwd)/.env --justfile ../../../single.just sign
```
