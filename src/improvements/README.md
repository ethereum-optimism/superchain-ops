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

> ⚠️ **IMPORTANT**: **Do not** update `mise` to a newer version unless you're told to do so by the maintainers of this repository. We pin to specific allowed versions of `mise` to reduce the likelihood of installing a vulnerable version of `mise`. You **must** use the `install-mise.sh` script to install `mise`.

1. Install dependencies:
```bash
cd src/improvements/
./script/install-mise.sh # Follow the instructions in the log output from this command to activate mise in your shell.
mise trust ../../mise.toml
mise install
just --justfile ../../justfile install
```

> For more information on `mise`, please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) guide.

2. Run tests:
Run all tests:
```bash
cd src/improvements/
just test # Run this command before asking for a review on any PR.
```

Run individual test suites:
```bash
forge test # Run solidity tests.
just simulate-all-templates # Run template regression tests.
```

3. Create a new task:
```bash
cd src/improvements/
just new task
```

Follow the interactive prompts from the `just new task` command to create a new task. This will create a new directory in the `tasks/` directory with the task name you provided. Please make sure to complete all the TODOs in the created files before submitting your task for review.

> Note: An `.env` file will be created in the new tasks directory. Please make sure to fill out the `TENDERLY_GAS` variable with a high enough value to simulate the task.

4. Configure the task in `config.toml` e.g.
```toml
l2chains = [{"name": "OP Mainnet", "chainId": 10}]
templateName = "<TEMPLATE_NAME>" # e.g. OPCMUpgradeV200

# Add template-specific config here.

[addresses]
# Addresses that are not discovered automatically (e.g. OPCM, StandardValidator, or safes missing from addresses.toml).
# IMPORTANT: If an address is defined here and also discovered onchain, this value takes precedence (e.g. ProxyAdminOwner).

[stateOverrides]
# State overrides (e.g. specify a Safe nonce).
```

The `[addresses]` TOML [table](https://toml.io/en/v1.0.0#table) is optional. It can be used to specify the addresses of the contracts involved in an upgrade. You can see an example of its use in this [task](./tasks/eth/009-opcm-update-prestate-v300-op+ink/config.toml).

The `[stateOverrides]` TOML table is optional, but in most cases we use it to specify the nonces of the multisig safes involved in an upgrade. Selecting the correct nonce is important and requires careful consideration. You can see an example of its use in this [task](./tasks/eth/009-opcm-update-prestate-v300-op+ink/config.toml). If you're unsure about the format of the `key` and `value` fields, you must default to using 66-character hex strings (i.e. `0x` followed by 64 hex characters). For example, setting the nonce for a Safe to `23` would look like:

```toml
# USE HEX ENCODED STRINGS WHEN POSSIBLE.
[stateOverrides]
0x847B5c174615B1B7fDF770882256e2D3E95b9D92 = [ 
    { key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = "0x0000000000000000000000000000000000000000000000000000000000000017" }
]
```

However, in some cases it's possible to use the decimal value directly:
```toml
# IN SOME CASES, YOU CAN USE THE DECIMAL VALUE DIRECTLY.
[stateOverrides]
0x847B5c174615B1B7fDF770882256e2D3E95b9D92 = [ 
    { key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 23 }
]
```

But **do not** pass the decimal value as a string—this will cause undefined behavior:
```toml
# ❌ INCORRECT: DO NOT USE STRINGIFIED DECIMALS.
[stateOverrides]
0x847B5c174615B1B7fDF770882256e2D3E95b9D92 = [ 
    { key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = "23" }
]
```

5. Simulate the task:
```bash
# Nested
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate <foundation|council|chain-governor|foundation-operations|base-operations|[custom-safe-name]>
```
> ℹ️ [custom-safe-name] refers to a Safe name defined manually by the task developer under the `[addresses]` table in the config.toml file.
> Example: NestedSafe1 in [sep/001-opcm-upgrade-v200/config.toml](./tasks/sep/001-opcm-upgrade-v200/config.toml).

```bash
# Single 
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```

6. Fill out the `README.md` and `VALIDATION.md` files.
    - If your task status is not `EXECUTED` or `CANCELLED`, it is considered non-terminal and will automatically be included in stacked simulations.
    - If your task has a `VALIDATION.md` file, you **must** fill out the `Normalized State Diff Hash Attestation` section. This is so that we can detect if the normalized state diff hash changes unexpectedly. You **must** also fill out the `Expected Domain and Message Hashes` section. This is so that we can detect if the domain and message hashes change unexpectedly. Any mismatches will cause the task to revert.

## FAQ

### How do I simulate a task that depends on another task?

> Note:
> Tasks get executed in the order they are defined in the `tasks/<network>/` directory. We use 3 digit prefixes to order the tasks e.g. `001-` is executed before `002-`, etc.

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

Another useful command is to list the tasks that will be simulated in a stacked simulation:
```bash
just list-stack <network> [task]
```

e.g.
```bash
just list-stack eth
# OR if you want to list the tasks up to and including a specific task.
just list-stack eth <your-task-name>
```

### How do I sign a task that depends on another task?

> **Note**: Only ledger signing is supported for stacked signing.

To sign a task, you can use the `just sign` command in `src/improvements/justfile`. This command will simulate all tasks up to and including the specified task, and then prompt you to sign the transaction for the final task in the stack using your Ledger device.

```bash
just sign <network> <task> [owner-safe-name] [hd-path]
```

**Example:**

To sign the `002-opcm-upgrade-v200` task on the Ethereum mainnet as the `foundation` safe, you would run:

```bash
just sign eth 002-opcm-upgrade-v200 foundation
```

The command will then:
1. List all the tasks that will be simulated in the stack.
2. Simulate the tasks in order.
3. Prompt you to approve the transaction on your Ledger device for the final task (`002-opcm-upgrade-v200` in this example).

### How do I make sure an address is universally available to any task?

We have provided the `addresses.toml` file to help you do this. This file is used to store commonly used addresses involved in an upgrade. You can access any of these addresses by name in your task's template.

The addresses in this file are loaded into two different address registry contracts, depending on the needs of your task: `SimpleAddressRegistry.sol` and `SuperchainAddressRegistry.sol`.

- **`SimpleAddressRegistry.sol`**: This is a straightforward key-value store for addresses. It's used for tasks that require a simple way to look up addresses by a human-readable name.

- **`SuperchainAddressRegistry.sol`**: This is a more advanced registry that automatically discovers addresses for contracts deployed across various chains in the Superchain. However, some addresses, like multisig safes or contracts not part of the standard deployment, cannot be discovered automatically. For these cases, `SuperchainAddressRegistry.sol` also loads addresses from `addresses.toml` to make them available.

Both registries load addresses based on the network the task is running on. For example, when running a task on Ethereum mainnet, addresses from the `[eth]` section of `addresses.toml` will be loaded. You can only access addresses for the network you are working on.

By adding an address to `addresses.toml`, you ensure it's available in your task's context, whether you're using the simple or the superchain address registry.

## Available Templates

All available templates can be found in the [template](./template/) directory. 
