# Template Creation Guide

This guide explains how to create and use templates for superchain tasks. The new template system allows developers to create tasks from existing template without writing Solidity code. A task developer can now create a task configuration file that conforms to the template's requirements and run the task using the simulation tooling.

## Overview

Templates are pre-built Solidity contracts that handle common task patterns. Each template is designed to work with configuration files that specify the parameters for different networks (mainnet, sepolia, devnet). This separation of template logic and configuration makes tasks:

- Easier to create (no Solidity code required)
- More secure (templates are already reviewed)
- Faster to review (standardized structure, minimal code changes)
- Flexible across networks (config-driven)

## Template System Architecture

### 1. Template Location and Usage

Templates are Solidity contracts located in the `src/improvements/template/` directory. Each template is designed for a specific type of task operation. To use a template:

1. Choose the appropriate template for your task
2. Specify the template in your config file using the `templateName` parameter
3. The `templateName` must match the template file name without the `.sol` extension

For example:
```toml
templateName = "GasConfigTemplate"  # Uses src/improvements/template/GasConfigTemplate.sol
```

### 2. Configuration File

Each task requires a configuration file named `config.toml`. This file specifies which L2 networks and contracts will be affected by the task.

### 3. L2 Chain Configuration

Every config file must specify the L2 chains that the task will interact with. This is done using the `l2chains` array:

```toml
l2chains = [
    {name = "Orderly", chainId = 291},
    {name = "Metal", chainId = 1750}
]
```

### 3. Template-Specific Configuration

Each template type has its own configuration structure. For example, a gas config template might look like:

```toml
[gasConfigs]
gasLimits = [
    {chainId = 291, gasLimit = 100000000},
    {chainId = 1750, gasLimit = 100000000}
]
```

## Creating a New Task Using Templates

To make developers lives easier when using a pre-existing template, a justfile task has been created to easily scaffold a new task from an existing template.

```
cd src/improvements/ 
just new task
```

Follow all instructions from the just file. This should output a new directory with a `README.md` and `config.toml` file pre-populated.


## Creating a New Template Type

To make developers lives easier when creating a new template, a justfile task has been created to easily scaffold a new template type.

```
cd src/improvements/ 
just new task
```

Follow all instructions from the just file. This should output a new Solidity file in the `src/improvements/template/` directory.
Go to this file and follow all instructions in the comments to create a new template. The task developer will need to fill out the following functions and data structures:

- TaskConfig struct - this struct should contain all the necessary parameters for the task to run.
- taskConfig mapping - this mapping should contain all of the necessary parameters for the task to run.
- safeAddressString function - return the name of the multisig address that will execute the task in the superchain-registry addresses.json file.
- _taskStorageWrites function - return the names of the addresses from the superchain-registry file whose storage will be written to in the task.
- _templateSetup function - set up any initial state for the task by reading in the `config.toml` file, saving the needed values for each chainid to storage, and then executing.
- _build function - build the task by executing the necessary logic for the task, specifically give instructions for how to handle each call based on the chainId passed. See the [GasConfigTemplate.sol](../template/GasConfigTemplate.sol) for an example of how to structure a _build function.
- _validate function - validate the task by checking that the state changes match the expected values. If the task is invalid, reverts. See the [GasConfigTemplate.sol](../template/GasConfigTemplate.sol) for an example of how to structure the _validate function.

## Example Templates

1. Gas Config Template (00)
   - Purpose: Set gas limits for L2 chains
   - Config structure: Uses `gasConfigs` section
   - Example:
     ```toml
     l2chains = [{name = "Orderly", chainId = 291}, {name = "Metal", chainId = 1750}]

      templateName = "GasConfigTemplate"

     [gasConfigs]
     gasLimits = [
         {chainId = 291, gasLimit = 100000000},
         {chainId = 1750, gasLimit = 100000000}
     ]
     ```
   - Variables:
     * chainId: The L2 chain identifier
     * gasLimit: Maximum gas limit for transactions on the L2 chain

2. Dispute Game Upgrade Template (01)
   - Purpose: Configure dispute game upgrades for L2 chains
   - Config structure:
     ```toml
     l2chains = [{name = "OP Mainnet", chainId = 10}]
     
     templateName = "DisputeGameUpgradeTemplate"
     
     implementations = [{
         gameType = 0,
         implementation = "0xf691F8A6d908B58C534B624cF16495b491E633BA",
         l2ChainId = 10
     }]
     ```
   - Variables:
     * gameType: The type of dispute game (e.g., 0 for default)
     * implementation: The address of the new dispute game implementation
     * l2ChainId: The chain ID where the upgrade will be applied

3. Game Type Template (02)
   - Purpose: Set respected game types for L2 chains
   - Config structure:
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
   - Variables:
     * deputyGuardian: Address of the deputy guardian for the game
     * gameType: The type of game to be respected (e.g. 1)
     * l2ChainId: The chain ID where the game type will be set
     * portal: The name of the portal proxy contract

## Running Tasks

To run a task, use the forge script command with the appropriate template and config file:

```bash
forge script <template-path> --sig "run(string)" <config-file-path> --rpc-url <network> -vvv
```

Example:
```bash
forge script src/improvements/template/GasConfigTemplate.sol --sig "run(string)" test/task/mock/example/task-00/config.toml --rpc-url mainnet -vvv
```

## Validation

After changes are applied in the simulation:
1. Automated validations run to verify the new values
2. The simulation checks that state changes match expectations
3. Any validation failures will cause the task to revert

## Best Practices

1. **Config File Organization**
   - Keep config files in your task directory
   - Use clear, descriptive names for parameters
   - Comment complex configurations

2. **Testing**
   - Run your task against sepolia or devnet before going to mainnet for larger upgrades
   - Verify state changes in simulation
   - Check validation results

3. **Documentation**
   - Document any special requirements
   - Explain parameter choices
   - When developing a new template, include at least one example config file

## Template Development (For Core Contributors)

When creating new templates:

1. Create the template contract in `src/improvement/templates/`
2. Implement standard build and validation patterns
3. Document the template's:
   - Purpose
   - Configuration structure
   - Validation rules
   - Usage examples

## Troubleshooting

Common issues and solutions:

1. **Config Parse Errors**
   - Verify TOML syntax
   - Ensure struct fields are alphabetically ordered in Solidity for parsing by foundry when creating a new template. See foundry [documentation](https://book.getfoundry.sh/cheatcodes/parse-json#decoding-json-objects-into-solidity-structs) for further explanation.
   - Check for required fields
   - Ensure chainIds match supported networks
   - Check config file path and name

2. **Validation Failures**
   - Review simulation output
   - Check parameters
   - Verify chain configurations
   - Increase forge script verbosity for more detailed error messages

3. **Simulation Errors**
   - RPC endpoints can cause intermittent errors
   - Verify state diff in tenderly and cli output match
   - Check for required permissions
