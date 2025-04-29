# Superchain-ops Task System

A tooling system for developers to write, test, and simulate onchain state changes safely before execution.

> 📚 More detailed documentation can be found in the [doc](./doc/) directory.

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

> Prerequisites:
> Make sure you have `mise` installed. Follow the [CONTRIBUTING.md](../../CONTRIBUTING.md) guide to install mise.

1. Create a new task:
```bash
cd src/improvements/
just new task
```

2. Configure the task in `config.toml` e.g.
```toml
l2chains = [{"name": "OP Mainnet", "chainId": 10}]
templateName = "<TEMPLATE_NAME>" # e.g. OPCMUpgradeV200

# Add template-specific config here.

[addresses]
# Addresses that are not automatically discovered (e.g. OPCM, StandardValidator or safes that are not found in addresses.toml).

[stateOverrides]
# State overrides (e.g. specify a Safe nonce).
```

3. Simulate the task:
```bash
# Nested
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate <foundation|council|chain-governor|foundation-operations|base-operations|[custom-safe-name]>
```
> ℹ️ [custom-safe-name] refers to a Safe name defined manually by the task developer in config.toml
> Example: NestedSafe1 in sep/001-opcm-upgrade-v200/config.toml.

```bash
# Single 
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```

4. Fill out the `README.md` and `VALIDATION.md` files.
    - If your task status is not `EXECUTED` or `CANCELLED`, it is considered non-terminal and will automatically be included in stacked simulations (which run on the main branch).

### How do I run a task that depends on another task?

Stacked simulations are supported. To use this feature, you can use the following command:
```bash
just simulate-stack <network> [task] [owner-address]
```

e.g. 
```bash
# Simulate all tasks up to and including the latest non-terminal task.
just simulate-stack eth
# OR to simulate up to and including a specific task. Useful if you don't care about simulating tasks after a certain point.
just simulate-stack eth 002-opcm-upgrade-v200
# OR to simulate up to and including a specific task, and specify the owner address to simulate as (useful for getting the correct domain and message hash).
just simulate-stack eth 002-opcm-upgrade-v200 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
```

## Available Templates

All available templates can be found in the [template](./template/) directory. 
