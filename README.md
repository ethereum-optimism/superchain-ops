> **⚠️ Important Notice: System Upgrade (August 2025)**
>
> The Superchain-ops system has undergone a significant upgrade. For access to historical executed tasks and previous system documentation, please refer to this [tag](https://github.com/ethereum-optimism/superchain-ops/tree/legacy-superchain-ops) for the archived tasks repository.
>
> • Need help? [Create an issue](https://github.com/ethereum-optimism/superchain-ops/issues) on this repo.

# Superchain-ops Task System

A tooling system for developers to write, test, and simulate onchain state changes safely before execution.

> 📚 More detailed documentation can be found in the [doc](src/doc/) directory.

## Repository Structure

The repository is organized as follows:

```
superchain-ops/
└── src/
      ├── template/     # Solidity template contracts (Template developers create templates here)
      └── doc/          # Detailed documentation
      └── tasks/        # Network-specific tasks
          ├── eth/     # Ethereum mainnet tasks (Task developers create tasks here)
          └── sep/     # Sepolia testnet tasks  (Task developers create tasks here)

```

## Quick Start

> ⚠️ **IMPORTANT**: **Do not** update `mise` to a newer version unless you're told to do so by the maintainers of this repository. We pin to specific allowed versions of `mise` to reduce the likelihood of installing a vulnerable version of `mise`. You **must** use the `install-mise.sh` script to install `mise`.

1. Install dependencies:
Run the commands below to set up your environment. `mise` is a **one-time setup** that ensures all signers and developers use the same dependency versions.
```bash
cd src/
./script/install-mise.sh # Follow the instructions in the log output from this command to activate mise in your shell.
mise activate   # Activate mise for the current shell; if it doesn’t take effect, restart your terminal.
mise trust ../mise.toml
mise install
just --justfile ../justfile install
```

> For more information on `mise`, please refer to the [CONTRIBUTING.md](./CONTRIBUTING.md) guide.

2. Run tests:
```bash
# Ensure you're in 'src/'
# cd src/
forge test # Run solidity tests.
```

3. Create a new task:
```bash
# Ensure you're in 'src/'
# cd src/
just new task
```

Follow the interactive prompts from the `just new task` command to create a new task. This will create a new directory in the `tasks/` directory with the task name you provided. Please make sure to complete all the TODOs in the created files before submitting your task for review.

> Note: An `.env` file will be created in the new tasks directory. Please make sure to fill out the `TENDERLY_GAS` variable with a high enough value to simulate the task.

4. Configure the task in `config.toml` e.g.
```toml
l2chains = [{"name": "OP Mainnet", "chainId": 10}]
templateName = "<TEMPLATE_NAME>" # e.g. OPCMUpgradeV200

allowOverwrite = ["<enter-address-name-here>"] # We may want to overwrite an address that is loaded from addresses.toml. e.g. 'SecurityCouncil'.

# Add template-specific config here.

[addresses]
# Addresses that are not discovered automatically (e.g. OPCM, StandardValidator, or safes missing from addresses.toml).
# IMPORTANT: If an address is defined here and also discovered onchain, this value takes precedence (e.g. ProxyAdminOwner).

[stateOverrides]
# State overrides (e.g. specify a Safe nonce).
```

The `allowOverwrite` TOML [array](https://toml.io/en/v1.0.0#array) is optional. It can be used to specify the addresses that we want to overwrite. You can see an example of its use in this [task](src/tasks/sep/020-gas-params-rehearsal-1-bn-0/config.toml). It's used when the user is adding an address to the `[addresses]` table that is already defined in the `addresses.toml` file.

The `[addresses]` TOML [table](https://toml.io/en/v1.0.0#table) is optional. It can be used to specify the addresses of the contracts involved in an upgrade. You can see an example of its use in this [task](src/tasks/eth/009-opcm-update-prestate-v300-op+ink/config.toml).

The `[stateOverrides]` TOML table is optional, but in most cases we use it to specify the nonces of the multisig safes involved in an upgrade. Selecting the correct nonce is important and requires careful consideration. You can see an example of its use in this [task](src/tasks/eth/009-opcm-update-prestate-v300-op+ink/config.toml). If you're unsure about the format of the `key` and `value` fields, you must default to using 66-character hex strings (i.e. `0x` followed by 64 hex characters). For example, setting the nonce for a Safe to `23` would look like:

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

**For individual task simulation** (from the task directory):

```bash
just --dotenv-path $(pwd)/.env simulate [child-safe-name-depth-1] [child-safe-name-depth-2]
```

**Examples:**
- **Single Safe Operations** (most common - see [SINGLE.md](src/SINGLE.md)):
  ```bash
  just --dotenv-path $(pwd)/.env simulate
  ```

- **Nested Safe Operations** (see [NESTED.md](src/NESTED.md)):
  ```bash
  just --dotenv-path $(pwd)/.env simulate foundation
  just --dotenv-path $(pwd)/.env simulate council
  just --dotenv-path $(pwd)/.env simulate chain-governor
  ```

- **Deeply Nested Safes** (child safe owned by another child safe):
  ```bash
  just --dotenv-path $(pwd)/.env simulate base-nested base-council
  ```

> ℹ️ [child-safe-name-depth-1] or [child-safe-name-depth-2] refers to a safe name defined manually by the task developer under the `[addresses]` table in the tasks config.toml file or under a given network (e.g. `[sep]`) in [`addresses.toml`](./src/addresses.toml) file.
> Example: NestedSafe1 in [sep/001-opcm-upgrade-v200/config.toml](src/tasks/sep/001-opcm-upgrade-v200/config.toml).

**For stacked simulation** (recommended - simulates dependencies):
```bash
cd src/
just simulate-stack <network> <task-name> [child-safe-name-depth-1] [child-safe-name-depth-2]
```

6. Create a Tenderly account. Once a user simulates a task, we print a Tenderly link. This allows us to compare our local simulation with Tenderly's simulation state changes. If you don’t already have a Tenderly account, go to https://dashboard.tenderly.co/login and sign up. The free account is sufficient.

7. Fill out the `README.md` and `VALIDATION.md` files.
    - If your task status is not `EXECUTED` or `CANCELLED`, it is considered non-terminal and will automatically be included in stacked simulations.
    - If your task has a `VALIDATION.md` file, you **must** fill out the `Expected Domain and Message Hashes` section. This is so that we can detect if the domain and message hashes change unexpectedly. Any mismatches will cause the task to revert.

## FAQ

### How do I simulate a task that depends on another task?

> Note:
> Tasks get executed in the order they are defined in the `tasks/<network>/` directory. We use 3 digit prefixes to order the tasks e.g. `001-` is executed before `002-`, etc.

Stacked simulations are supported. To use this feature, you can use the following command:
```bash
just simulate-stack <network> [task] [child-safe-name-depth-1] [child-safe-name-depth-2]
```

e.g.
```bash
just simulate-stack eth                                       # Simulate all tasks for ethereum
just simulate-stack eth 001-example                           # Simulate specific task on root safe
just simulate-stack eth 001-example foundation                # Simulate on foundation child safe
just simulate-stack eth 001-example base-nested base-council  # Simulate on nested architecture
SKIP_DECODE_AND_PRINT=1 just simulate-stack eth               # By using the 'SKIP_DECODE_AND_PRINT' environment variable, you'll have faster stacked simulations. However, markdown will not be printed to the terminal.
```

> **Note**: For nested architectures, specify child safes in ownership order: depth-1 safe (owned by root) then depth-2 safe (owned by depth-1).

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

To sign a task, you can use the `just sign-stack` command in `src/justfile`. This command will simulate all tasks up to and including the specified task, and then prompt you to sign the transaction for the final task in the stack using your signing device.

```bash
just sign-stack <network> <task> [child-safe-name-depth-1] [child-safe-name-depth-2]
```

**Environment variables:**
- `HD_PATH` - Hardware wallet derivation path index (default: 0). The value is inserted into the [BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki) Ethereum path as `m/44'/60'/$HD_PATH'/0/0` (e.g. `0` -> `m/44'/60'/0'/0/0`, `1` -> `m/44'/60'/1'/0/0`). Use this to select the desired Ethereum account on your hardware wallet.
- `USE_KEYSTORE` - If set, uses keystore instead of ledger. By default, keys are stored under `~/.foundry/keystores`.

**Examples:**

To sign the `002-opcm-upgrade-v200` task on the Ethereum mainnet as the `foundation` safe:

```bash
just sign-stack eth 002-opcm-upgrade-v200 foundation
```

To use a custom HD path:

```bash
HD_PATH=1 just sign-stack eth 002-opcm-upgrade-v200 foundation
```

To use keystore instead of ledger:

```bash
USE_KEYSTORE=1 just sign-stack eth 002-opcm-upgrade-v200 foundation
```

The command will then:
1. List all the tasks that will be simulated in the stack.
2. Simulate the tasks in order.
3. Prompt you to approve the transaction on your Ledger device for the final task (`002-opcm-upgrade-v200` in this example).

### How do I perform a contract upgrade directly on an L2?

You can execute an upgrade directly on an L2 (e.g. `op-sepolia`). `SuperchainAddressRegistry` detects that the task is upgrading directly via an L2. It does this by looking at the RPC url, which is decided by the directory that the task is contained within (i.e. `tasks/opsep`).

- Create your task in the correct directory for your L2 (e.g. `opsep`).
- Set `l2chains` to the chain you're targetting.
- Set `fallbackAddressesJsonPath` in `config.toml`.
- In `addresses.json` (keyed by chainId), include every identifier your template uses (e.g., `ProxyAdminOwner`, `ProxyAdmin`, `<Identifier>`).

`config.toml`:

```toml
l2chains = [{ name = "<CHAIN_NAME>", chainId = <CHAIN_ID> }]
fallbackAddressesJsonPath = "<relative/path/to/addresses.json>"
templateName = "<YOUR_TEMPLATE_NAME>"
# template-specific fields...
```

`addresses.json`:
```json
{
  "<CHAIN_ID>": {
    "ProxyAdminOwner": "0x...",
    "ProxyAdmin": "0x...",
    "<IdentifierYourTemplateUses>": "0x..."
  }
}
```

Example: see [`test/tasks/example/opsep/001-set-eip1967-impl`](/test/tasks/example/opsep/001-set-eip1967-impl/).

### How do I add a private key to my keystore?

Use Foundry's keystore. Import your key and set a password when prompted:

```bash
cast wallet import my-account-name --private-key <priv-key>
```

By default, keys are stored under `~/.foundry/keystores`. List accounts with `cast wallet list`. When running signing commands with `USE_KEYSTORE=1`, you'll be prompted for the keystore password.

See the official Foundry docs for the [cast wallet import](https://getfoundry.sh/cast/reference/wallet/) command.

### How do I make sure an address is universally available to any task?

We have provided the [`addresses.toml`](./src/addresses.toml) file to help you do this. This file is used to store commonly used addresses involved in an upgrade. You can access any of these addresses by name in your task's template.

The addresses in this file are loaded into two different address registry contracts, depending on the needs of your task: `SimpleAddressRegistry.sol` and `SuperchainAddressRegistry.sol`.

- **`SimpleAddressRegistry.sol`**: This is a straightforward key-value store for addresses. It's used for tasks that require a simple way to look up addresses by a human-readable name.

- **`SuperchainAddressRegistry.sol`**: An advanced registry designed to automatically discover contract addresses deployed across chains in the Superchain. For this to work, the target chain must be listed in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry). While standard deployments can be discovered automatically, some addresses such as multisig safes or custom contracts require manual inclusion. In these cases, `SuperchainAddressRegistry.sol` also loads entries from [`addresses.toml`](./src/addresses.toml) to ensure availability. If you're working with a chain not yet included in the Superchain registry, you can manually provide a fallback JSON file via `fallbackAddressesJsonPath` in your task's `config.toml`. See the section [below](#what-if-i-want-to-upgrade-a-chain-that-is-not-in-the-superchain-registry) for details.

Both registries load addresses based on the network the task is running on. For example, when running a task on Ethereum mainnet, addresses from the `[eth]` section of [`addresses.toml`](./src/addresses.toml) will be loaded. You can only access addresses for the network you are working on.

By adding an address to [`addresses.toml`](./src/addresses.toml), you ensure it's available in your task's context, whether you're using the simple or the superchain address registry.

### What if I want to upgrade a chain that is not in the superchain-registry?

If the chain you want to upgrade is not in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry), you can manually provide a fallback JSON file in your task's `config.toml` (as `fallbackAddressesJsonPath`).

```toml
l2chains = [{name = "Unichain", chainId = 1333330}]
fallbackAddressesJsonPath = "test/tasks/example/eth/010-transfer-owners-local/addresses.json"
templateName = "TransferOwners"
```

See: [example/eth/010-transfer-owners-local/config.toml](test/tasks/example/eth/010-transfer-owners-local/config.toml) for an example.

The fallback JSON file must be structured with the chain ID as the top-level key, containing all contract addresses for that chain. It takes the same structure as the superchain-registry's [addresses.json](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/extra/addresses/addresses.json) file.

When the task runs, it will first attempt to use the superchain-registry. If the chain is not found, it will load addresses directly from your fallback JSON file instead of performing automatic onchain discovery.

> ⚠️ **Note**: You must manually provide all contract addresses required by your task template in the fallback JSON file.

## Available Templates

All available templates can be found in the [template](src/template/) directory.
