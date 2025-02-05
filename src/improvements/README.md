# Overview

This new calldata simulation tooling allows developers to write tasks that simulate the state changes that would occur onchain if the task were to be executed. The simulator can be run against any mainnet, sepolia, and devnet.

The goal of using this new task tooling for the superchain ops repo is to greatly simplify task development, increase security by reducing errors, reduce sharp edges, and speed development and review of tasks. The simulation is designed to simulate task runs, with all onchain state changes being run locally.

## Task Development and Templates

Developers can now create tasks without writing any Solidity code by using predefined templates. Each template is designed to handle specific types of operations (e.g., gas configuration, dispute game upgrades) and is configured through TOML files. This template-based approach ensures consistency, reduces errors, and speeds up task development.

# Task Configuration Files

Each task requires a `config.toml` file that specifies:
1. The L2 chains the task will interact with
2. Template-specific configuration parameters

## Template Usage

Every task must specify which template to use via the `templateName` parameter. Templates can be found in the `src/improvements/template/` directory. The template name should match the template file name without the `.sol` extension.

For example:
```toml
templateName = "GasConfigTemplate"  # Uses src/improvements/template/GasConfigTemplate.sol
```

## L2 Chain Configuration

Every config file must specify the L2 chains that the task will interact with using the `l2chains` array:

```toml
# L2Chains is a list of the L2 chains that the task will interact with
l2chains = [
    {name = "Orderly", chainId = 291},
    {name = "Metal", chainId = 1750},
    {name = "OP Mainnet", chainId = 10}
]
```

## Available Templates

### 1. Gas Config Template (00)
Purpose: Set gas limits for L2 chains
```toml
l2chains = [{name = "Orderly", chainId = 291}, {name = "Metal", chainId = 1750}]

[gasConfigs]
gasLimits = [
    {chainId = 291, gasLimit = 100000000},
    {chainId = 1750, gasLimit = 100000000}
]
```

### 2. Dispute Game Upgrade Template (01)
Purpose: Configure dispute game implementations
```toml
l2chains = [{name = "OP Mainnet", chainId = 10}]

templateName = "DisputeGameUpgradeTemplate"

implementations = [{
    gameType = 0,
    implementation = "0xf691F8A6d908B58C534B624cF16495b491E633BA",
    l2ChainId = 10
}]
```

### 3. Game Type Template (02)
Purpose: Set respected game types for L2 chains
```toml
l2chains = [{name = "OP Mainnet", chainId = 10}]

templateName = "SetGameTypeTemplate"

respectedGameTypes = [{
    deputyGuardian = "0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B",
    gameType = 1,
    l2ChainId = 10,
    portal = "OptimismPortalProxy"
}]
```

## Running Tasks

Tasks can be executed using the forge script command with the appropriate template and config file:

```bash
forge script <template-path> --sig "run(string)" <config-directory-path>/config.toml --rpc-url <network> -vvv
```

### Example Commands

#### Template 00 (Gas Config):
```bash
forge script src/improvements/template/GasConfigTemplate.sol --sig "run(string)" test/task/mock/example/task-00/config.toml --rpc-url mainnet -vvv
```

#### Template 01 (Dispute Game Upgrade):
```bash
forge script src/improvements/template/DisputeGameUpgradeTemplate.sol --sig "run(string)" test/task/mock/example/task-01/config.toml --rpc-url mainnet -vvv
```

#### Template 02 (Game Type):
```bash
forge script src/improvements/template/SetGameTypeTemplate.sol --sig "run(string)" test/task/mock/example/task-02/config.toml --rpc-url mainnet -vvv
```

## Validation

After changes are applied in the simulation:
1. Automated validations run to verify the new values
2. The simulation checks that state changes match expectations
3. Any validation failures will cause the task to revert

For detailed information about creating templates and configuring tasks, see [TEMPLATE_CREATION.md](./doc/TEMPLATE_CREATION.md).
