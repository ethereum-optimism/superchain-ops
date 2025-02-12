# New Template Creation Guide

This guide explains how to create new Solidity templates for the superchain task system. Templates are the foundation for standardizing and securing task execution across different networks.

## Quick Start

To scaffold a new template:

```bash
cd src/improvements/
just new template
```

This will create a new Solidity file in `src/improvements/template/` with the basic structure required.

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
    return "OptimismMultisig";
}
```

#### _taskStorageWrites
Lists addresses from superchain-registry whose storage will be modified:
```solidity
function _taskStorageWrites() internal pure override returns (string[] memory) {
    return ["SystemConfig"];
}
```

All addresses listed here must have their storage modified during task execution.

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
    // make sure to user verbose error messages for better debugging
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

## Cross-Network Compatibility

Templates must handle:

1. Network-Specific Logic
```solidity
if (chainId == MAINNET_CHAIN_ID) {
    // Mainnet-specific logic
} else if (chainId == TESTNET_CHAIN_ID) {
    // Testnet-specific logic
}
```

2. Address Resolution
```solidity
// Use registry to get network-specific addresses
address target = _getAddress(chainId, "ContractName");
```

3. Gas Configuration
```solidity
// Handle different gas requirements per network
uint256 gasLimit = _getGasLimit(chainId);
```

## Error Handling

1. Input Validation
```solidity
require(param > 0, "Invalid parameter");
require(address(contract) != address(0), "Invalid contract");
```

2. State Validation
```solidity
require(
    contract.getValue() == expectedValue,
    "Validation failed: incorrect value"
);
```

3. Network Checks
```solidity
require(
    _isValidChainId(chainId),
    "Unsupported network"
);
```

## Best Practices

1. Code Organization
- Clear function names
- Good code comments
- Logical grouping of functionality

2. Security
- Access control checks
- Input validation
- State change verification

3. Documentation
- Clear parameter descriptions
- Usage examples

## Example Implementation

Here's a basic template example:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTemplate.sol";

contract ExampleTemplate is BaseTemplate {
    struct TaskConfig {
        uint256 value;
        address target;
    }
    
    mapping(uint256 => TaskConfig) public taskConfig;
    
    function safeAddressString() internal pure override returns (string memory) {
        return "OptimismMultisig";
    }
    
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "ExampleContract";
        return storageWrites;
    }
    
    function _templateSetup() internal override {
        bytes memory configBytes = vm.parseToml(configFile);
        
        for (uint256 i; i < l2Chains.length; i++) {
            uint256 chainId = l2Chains[i].chainId;
            taskConfig[chainId] = TaskConfig({
                value: // Parse from config,
                target: // Parse from config
            });
        }
    }
    
    function _build(uint256 chainId) internal override {
        TaskConfig memory config = taskConfig[chainId];
        
        // Implement task logic
        IExampleContract target = IExampleContract(config.target);
        target.setValue(config.value);
    }
    
    function _validate(uint256 chainId) internal override {
        TaskConfig memory config = taskConfig[chainId];
            
        // Validate changes
        IExampleContract target = IExampleContract(addresses.getAddress("ExampleContract", chainId));

        assertEq(
            config.value,
            target.getValue(),
            "Validation failed: incorrect value"
        );
    }
}
```

## Troubleshooting

1. Common Issues
- Config parsing errors
- Address naming issues

2. Debug Tools
- Use forge verbosity flags
- Check simulation output
- Review state changes