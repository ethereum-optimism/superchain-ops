# 034-worldchain-key-handback-over: Returning L2PAO back to original EOA

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Transfer the L2 ProxyAdmin Owner for Worldchain Sepolia to [Alchemy-controlled EOA](https://www.notion.so/oplabs/Worldchain-key-handback-over-address-validation-272f153ee1628002bfa2e00a718c57d5?source=copy_link).

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
