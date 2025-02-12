# New Template Creation Guide

This guide explains how to create new Solidity templates for the superchain task system. Templates are the foundation for standardizing and securing task execution across different networks.

## Quick Start

To scaffold a new template:

```bash
cd src/improvements/
just new template
```

This will create a new Solidity file in `src/improvements/template/` with the basic template structure required.

## Template Structure

### 1. Required Components

Every template must implement the following functions:

```solidity
// Required data structures
struct TaskConfig {
    // Template-specific configuration parameters
}

// Storage mapping
mapping(uint256 => TaskConfig) public taskConfig;

// Core functions
function safeAddressString() internal pure override returns (string memory);
function _taskStorageWrites() internal pure override returns (string[] memory);
function _templateSetup(string memory taskConfigFilePath) internal override;
function _build(uint256 chainId) internal override;
function _validate(uint256 chainId) internal override;
```

The struct and mapping are optional and can be customized based on task requirements. As a general rule, task developers should think of everything as a template, hence the chainId flag to the build and validate functions.

### 2. Function Implementations

#### safeAddressString
Returns the name of the multisig address from the superchain-registry:
```solidity
function safeAddressString() internal pure override returns (string memory) {
    return "SystemConfigOwner";
}
```

#### _taskStorageWrites
Lists addresses from superchain-registry whose storage will be modified:
```solidity
function _taskStorageWrites() internal pure override returns (string[] memory) {
    return ["SystemConfigProxy"];
}
```

All addresses listed here **must** have their storage modified during task execution. If an address is listed but its storage is not modified, the execution will revert.

#### _templateSetup
Initializes the task state from config.toml:
```solidity
function _templateSetup(string memory taskConfigFilePath) internal override {
    // Parse config file
    bytes memory configBytes = vm.parseToml(vm.readFile(taskConfigFilePath));
    
    // Save configuration to storage
    for (uint256 i; i < l2Chains.length; i++) {
        uint256 chainId = l2Chains[i].chainId;
        taskConfig[chainId] = TaskConfig({
            // Set template-specific parameters
        });
    }
}
```

TODO: fix later once OPCM changes land with buildSingle and buildChain

#### _build
Implements the task logic for each chain:
```solidity
function _build(uint256 chainId) internal override {
    TaskConfig memory config = taskConfig[chainId];
    
    // Implement task-specific logic
    // Use config parameters to make state changes
    // Handle any necessary contract interactions
}
```

#### _validate
Verifies the task executed correctly:
```solidity
function _validate(uint256 chainId) internal override {
    TaskConfig memory config = taskConfig[chainId];
        
    // Verify state changes using assertEq, assertTrue, assertFalse foundry test functions
    // make sure to use verbose error messages for better debugging
}
```

## Configuration Structure

### 1. TaskConfig Struct

Define all parameters needed for the task:

```solidity
struct TaskConfig {
    // Base parameters
    uint256 chainId;
    
    // Template-specific parameters
    uint256 gasLimit;
    bytes32 configHash;
    // Add other required fields
}
```

### 2. TOML Configuration

Create a corresponding TOML structure:

```toml
templateName = "YourTemplateName"

l2chains = [
    {name = "Chain1", chainId = 123},
    {name = "Chain2", chainId = 456}
]

[templateConfig]
parameter1 = "value1"
parameter2 = 123
```

## Existing Templates

Existing templates can be found in the [`src/improvements/template/`](../template) directory. These templates can be used as a reference for creating new templates.
