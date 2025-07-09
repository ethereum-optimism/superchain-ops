# 020-gas-params-rehearsal-1-bn-0: Testing task against a devnet with local addresses.json

Status: [READY FOR REVIEW]()

## Objective

Testing task against a devnet with local addresses.json. This will send no-op txs to the SystemConfig contract, which will ensure the process works without making any configuration changes.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/020-gas-params-rehearsal-1-bn-0
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/020-gas-params-rehearsal-1-bn-0
just --dotenv-path $(pwd)/.env --justfile ../../../single.just sign
```
