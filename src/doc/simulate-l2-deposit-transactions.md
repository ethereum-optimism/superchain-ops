# Simulating L2 Deposit Transactions with Integration Tests

The following steps describe how to automatically simulate L2 deposit transactions prior to L1 task execution using integration tests. This approach is based on the [manual Tenderly simulation approach](./simulate-l2-ownership-transfer.md), with the difference that it uses a local supersim instance and automated transaction replay instead of manual Tenderly simulation.

## Overview

When executing L1 transactions that trigger L2 deposit transactions (via OptimismPortal), we can gain additional confidence by automatically replaying these deposit transactions on local L2 forks, simulating what op-node does. The `IntegrationBase` contract provides a `_relayAllMessages` function that:

1. Extracts all `TransactionDeposited` events from the L1 execution
2. Filters events by portal address to ensure only relevant events are relayed to each L2
3. Decodes the deposit transaction parameters
4. Executes each transaction on the corresponding L2 fork(s) with the correct sender
5. Asserts that all transactions succeed

This automated approach is particularly useful for:
- Complex tasks that emit multiple deposit transactions (e.g., revenue share upgrades with 12+ transactions per chain)
- Multi-chain deployments where the same L1 transaction affects multiple L2s

## Prerequisites

### Supersim Setup

You'll need to run supersim with forked chains to test against real network state. Supersim is a lightweight tool that runs local L1 and L2 nodes with forking capabilities.

Install supersim if you haven't already:

https://github.com/ethereum-optimism/supersim

Start supersim with forked chains for multiple L2s:

```bash
supersim fork --chains=op,ink,soneium
```

**Note:** You can specify any L2 chains supported by supersim (e.g., `op`, `base`, `mode`, `ink`, `soneium`, etc.). The default ports are:
- L1 (Ethereum): `http://127.0.0.1:8545`
- L2 (OP Mainnet): `http://127.0.0.1:9545`
- L2 (Ink Mainnet): `http://127.0.0.1:9546`
- L2 (Soneium Mainnet): `http://127.0.0.1:9547`
- Additional L2s will increment the port (9548, 9549, etc.)

For different L2 chains, adjust the RPC URLs and network IDs accordingly.

## Creating an Integration Test

### Step 1: Inherit from IntegrationBase

Create a test contract that inherits from `IntegrationBase`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IntegrationBase} from "test/integration/IntegrationBase.t.sol";
import {YourTemplate} from "src/template/YourTemplate.sol";

contract YourIntegrationTest is IntegrationBase {
    YourTemplate public template;
    
    // Fork IDs
    uint256 internal _mainnetForkId;
    uint256 internal _opMainnetForkId;
    uint256 internal _inkMainnetForkId;
    
    // Portal addresses (L1)
    address internal constant OP_MAINNET_PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address internal constant INK_MAINNET_PORTAL = 0x5d66C1782664115999C47c9fA5cd031f495D3e4F;
    
    function setUp() public {
        // Create forks pointing to supersim instances
        _mainnetForkId = vm.createFork("http://127.0.0.1:8545");
        _opMainnetForkId = vm.createFork("http://127.0.0.1:9545");
        _inkMainnetForkId = vm.createFork("http://127.0.0.1:9546");
        
        // Deploy template on L1 fork
        vm.selectFork(_mainnetForkId);
        template = new YourTemplate();
    }
}
```

### Step 2: Execute L1 Transaction and Relay Messages

In your test function, execute the L1 transaction while recording logs, then relay all deposit messages to multiple L2s:

```solidity
function test_yourTask_integration() public {
    string memory _configPath = "path/to/your/config.toml";
    
    // Step 1: Record logs for L1→L2 message replay
    vm.recordLogs();
    
    // Step 2: Execute task simulation
    template.simulate(_configPath);
    
    // Step 3: Relay deposit transactions from L1 to all L2s
    uint256[] memory forkIds = new uint256[](2);
    forkIds[0] = _opMainnetForkId;
    forkIds[1] = _inkMainnetForkId;
    
    address[] memory portals = new address[](2);
    portals[0] = OP_MAINNET_PORTAL;
    portals[1] = INK_MAINNET_PORTAL;
    
    // Pass true for _isSimulate since simulate() emits events twice
    // (once during dry-run validation, once during actual simulation)
    _relayAllMessages(forkIds, true, portals);
    
    // Step 4: Assert the state of each L2 chain
    vm.selectFork(_opMainnetForkId);
    // Add OP Mainnet assertions here...
    
    vm.selectFork(_inkMainnetForkId);
    // Add Ink Mainnet assertions here...
}
```

### Step 3: Add State Assertions

After relaying messages, assert that the L2 state matches expectations:

```solidity
// Example: Checking a contract's owner
assertEq(
    OwnableUpgradeable(l2Contract).owner(),
    vm.parseTomlAddress(_config, ".newOwner")
);

// Example: Checking a configuration value
assertEq(
    IYourContract(l2Contract).someValue(),
    vm.parseTomlUint(_config, ".expectedValue")
);
```

## Example: Revenue Share Integration Test

See [RevShareContractsUpgraderIntegration.t.sol](../../test/integration/RevShareContractsUpgraderIntegration.t.sol) for a complete example that:

- Tests multi-chain deployments (OP Mainnet and Ink Mainnet simultaneously)
- Validates multiple L2 contracts (L1Withdrawer, RevShareCalculator, FeeSplitter, FeeVaults)
- Asserts complex state relationships between contracts
- Uses portal filtering to ensure correct event routing

Key test structure:

```solidity
function test_upgradeAndSetupRevShare_integration() public {
    // Step 1: Record logs for L1→L2 message replay
    vm.recordLogs();
    
    // Step 2: Execute task simulation
    revShareTask.simulate("test/tasks/example/eth/016-revshare-upgrade-and-setup/config.toml");
    
    // Step 3: Relay deposit transactions from L1 to all L2s
    uint256[] memory forkIds = new uint256[](2);
    forkIds[0] = _opMainnetForkId;
    forkIds[1] = _inkMainnetForkId;
    
    address[] memory portals = new address[](2);
    portals[0] = OP_MAINNET_PORTAL;
    portals[1] = INK_MAINNET_PORTAL;
    
    _relayAllMessages(forkIds, IS_SIMULATE, portals);
    
    // Step 4: Assert the state of the OP Mainnet contracts
    vm.selectFork(_opMainnetForkId);
    _assertL2State(OP_L1_WITHDRAWER, OP_REV_SHARE_CALCULATOR, ...);
    
    // Step 5: Assert the state of the Ink Mainnet contracts
    vm.selectFork(_inkMainnetForkId);
    _assertL2State(INK_L1_WITHDRAWER, INK_REV_SHARE_CALCULATOR, ...);
}
```

## Understanding the Output

When you run an integration test, `_relayAllMessages` will output for each L2:

```
================================================================================
=== Relaying Deposit Transactions on L2                                    ===
=== Portal: 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed
=== Network is set to 10                                                    ===
================================================================================

=== Summary ===
Total transactions processed: 11
Successful transactions: 11
Failed transactions: 0
```

This output repeats for each L2 chain being tested, with different portal addresses and chain IDs.

## Portal Filtering

The `_relayAllMessages` function filters events by portal address to ensure that only deposit transactions meant for a specific L2 are relayed to that chain. This is critical for multi-chain deployments where:

1. A single L1 transaction may emit deposit transactions to multiple L2 chains
2. Each L2 should only receive transactions deposited through its corresponding portal
3. The portal address identifies which OptimismPortal emitted the `TransactionDeposited` event

For example:
- Events from `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` (OP Mainnet Portal) → OP Mainnet fork
- Events from `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` (Ink Mainnet Portal) → Ink Mainnet fork

This filtering prevents cross-contamination of deposit transactions between chains.

## Troubleshooting

### Fork Issues
When first running the fork test against supersim, do it with a `--match-test` that does only one fork for caching the network states. If you try to run more than one at the same time by, for example, using `--match-contract`, you might get timeout issues
