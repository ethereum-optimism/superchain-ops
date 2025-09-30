# 034-worldchain-key-handback-over: Returning L2PAO back to original EOA

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Todo: Describe the objective of the task

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/034-worldchain-key-handback-over
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands for each safe:
```bash
cd src/tasks/sep/034-worldchain-key-handback-over
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
