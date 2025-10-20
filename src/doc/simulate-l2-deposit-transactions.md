# Simulating L2 Deposit Transactions with Integration Tests

The following steps describe how to automatically simulate L2 deposit transactions prior to L1 task execution using integration tests. This approach is similar to the [manual Tenderly simulation approach](./simulate-l2-ownership-transfer.md), with the key difference being that it uses a local supersim instance and automated transaction replay instead of manual Tenderly simulation.

## Overview

When executing L1 transactions that trigger L2 deposit transactions (via the OptimismPortal), we can gain additional confidence by automatically replaying these deposit transactions on a local L2 fork, simulating what op-node does. The `IntegrationBase` contract provides a `_relayAllMessages` function that:

1. Extracts all `TransactionDeposited` events from the L1 execution
2. Decodes the deposit transaction parameters
3. Executes each transaction on the L2 fork with the correct aliased sender
4. Generates Tenderly simulation links for each transaction
5. Asserts that all transactions succeed

This automated approach is particularly useful for complex tasks that emit multiple deposit transactions, such as the revenue share upgrade path which can emit 12+ deposit transactions per execution.

## Prerequisites

### Supersim Setup

You'll need to run supersim with forked chains to test against real network state. Supersim is a lightweight tool that runs local L1 and L2 nodes with forking capabilities.

Install supersim if you haven't already:
```bash
# Installation instructions: https://github.com/ethereum-optimism/supersim
```

Start supersim with forked chains:
```bash
supersim fork --chains=op --interop.enabled
```

**Note:** You can use any L2 chain supported by supersim (e.g., `op`, `base`, `mode`, etc.). The default ports are:
- L1 (Ethereum): `http://127.0.0.1:8545`
- L2 (OP Mainnet): `http://127.0.0.1:9545`

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
    uint256 internal _l2ForkId;
    
    function setUp() public {
        // Create forks pointing to supersim instances
        _mainnetForkId = vm.createFork("http://127.0.0.1:8545");
        _l2ForkId = vm.createFork("http://127.0.0.1:9545");
        
        // Deploy template on L1 fork
        vm.selectFork(_mainnetForkId);
        template = new YourTemplate();
    }
}
```

### Step 2: Execute L1 Transaction and Relay Messages

In your test function, execute the L1 transaction while recording logs, then relay all deposit messages to L2:

```solidity
function test_yourTask_integration() public {
    string memory _configPath = "path/to/your/config.toml";
    
    // Step 1: Execute L1 transaction recording logs
    vm.recordLogs();
    template.simulate(_configPath, new address[](0));
    
    // Step 2: Relay messages from L1 to L2
    // Pass true for _isSimulate since simulate() emits events twice
    // (once during dry-run validation, once during actual simulation)
    _relayAllMessages(_l2ForkId, true);
    
    // Step 3: Assert the state of the L2 contracts
    string memory _config = vm.readFile(_configPath);
    
    // Add your L2 state assertions here...
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

See [RevenueShareIntegration.t.sol](../../test/integration/RevenueShareIntegration.t.sol) for a complete example that:

- Tests both opt-in and opt-out scenarios
- Tests late opt-in scenarios
- Validates multiple L2 contracts (L1Withdrawer, RevShareCalculator, FeeSplitter, FeeVaults)
- Asserts complex state relationships between contracts

Key test structure:
```solidity
function test_optInRevenueShare_integration() public {
    // 1. Execute L1 transaction
    vm.recordLogs();
    revenueShareTemplate.simulate(_configPath, new address[](0));
    
    // 2. Relay messages to L2
    _relayAllMessages(_l2ForkId, true);
    
    // 3. Assert L2 state
    assertEq(IL1Withdrawer(L1_WITHDRAWER).minWithdrawalAmount(), expectedValue);
    assertEq(IFeeSplitter(FEE_SPLITTER).sharesCalculator(), REV_SHARE_CALCULATOR);
    // ... more assertions
}
```

## Understanding the Output

When you run an integration test, `_relayAllMessages` will output:

```
================================================================================
=== Replaying Deposit Transactions on L2                                    ===
=== Each transaction includes Tenderly simulation link                      ===
=== Network is set to 10 (OP Mainnet) - adjust if testing on different L2  ===
================================================================================

Tenderly Simulation Link for transaction #1
https://dashboard.tenderly.co/TENDERLY_USERNAME/TENDERLY_PROJECT/simulator/new?network=10&contractAddress=0x...&from=0x...&gas=656536&value=0&rawFunctionInput=0x...

Tenderly Simulation Link for transaction #2
...

=== Summary ===
Total transactions: 12
Successful transactions: 12
Failed transactions: 0
```

## Manual Tenderly Simulation

While integration tests provide automated validation, you can also manually simulate individual transactions in Tenderly by:

1. Copying a Tenderly link from the integration test output
2. Opening the link in your browser
3. Inspecting the transaction details, state changes, and gas usage

For detailed manual simulation steps, see [simulate-l2-ownership-transfer.md](./simulate-l2-ownership-transfer.md).

## Recording Simulation Results

After running integration tests and generating Tenderly simulations, document the results in your task's validation file. See [RevenueShareSimulations.md](../../test/integration/tenderly/RevenueShareSimulations.md) for an example format:

```markdown
# Your Task Simulations

### Scenario 1
1. [Contract Deploy](https://www.tdly.co/shared/simulation/...) Gas: 558,056/656,536 (85%)
2. [Contract Upgrade](https://www.tdly.co/shared/simulation/...) Gas: 65,138/150,000 (43%)
...
```

## Troubleshooting

### Failed Tenderly Transactions but working in the Supersim integration
Something that sucks on the Tenderly simulations is that it is very hard (actually I don't know how) to keep the state changes of previously simulated transactions. So if you are testing the transactions of a task that first -> upgrades a contract to have setters and then -> calls that setter, when simulating the setter transaction, it will revert. This is the reason why the rev share late opt in transactions don't have tenderly simulations linked


### Fork Issues
When first running the fork test against supersim, do it with a `--match-test` that does only one fork for caching the network states. If you try to run more than one at the same time by, for example, using `--match-contract`, you might get timeout issues