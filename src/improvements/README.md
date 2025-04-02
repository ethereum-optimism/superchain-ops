# Superchain Upgrade Task System

A tooling system that enables developers to write and test tasks that simulate onchain state changes before execution.

You can find more detailed documentation in the [doc](./doc/) directory.

## Repository Structure

The repository is organized as follows:

```
superchain-ops/
└── src/
    └── improvements/
       ├── template/     # Solidity template contracts (Template developers create templates here)
       └── doc/          # Detailed documentation
       └── tasks/        # Network-specific tasks
            ├── eth/     # Ethereum mainnet tasks (Task developers create tasks here)
            └── sep/     # Sepolia testnet tasks  (Task developers create tasks here)
```

## Quick Start

1. Create a new task:
```bash
cd src/improvements/
just new task
```

2. Configure the task in `config.toml`:
```toml
l2chains = [{"name": "OP Mainnet", "chainId": 10}]
templateName = "GasConfigTemplate"
```

3. Simulate the task:
```bash
# Nested 
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate <foundation|council|chain-governor>
# Single 
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```

## Available Templates

All available templates can be found in the [template](./template/) directory. 
