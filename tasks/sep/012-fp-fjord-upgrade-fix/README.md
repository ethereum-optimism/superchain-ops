# Sepolia FP Upgrade - Fjord Fix

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x1ea26d9aa123aceaf781f6c0f295fbf228a7d8d5f17fe0365e7896d42bee7ce0)

## Objective

Upgrades the deployed system on `sepolia` to use the appropriate `DelayedWETH` proxy for dispute games.

This fixes a misconfiguration from a prior upgrade.

## Pre-deployments

The `FaultDisputeGame` has been deployed at [`0xA4E392d63AE6096DB5454Fa178E2F8f99F8eF0ef`](https://sepolia.etherscan.io/address/0xA4E392d63AE6096DB5454Fa178E2F8f99F8eF0ef).

The `PermissionedDisputeGame` has been deployed at [`0x864fbE13Bb239521a8c837A0aA7c7122ee3eb0b2`](https://sepolia.etherscan.io/address/0x864fbE13Bb239521a8c837A0aA7c7122ee3eb0b2).

The new implementations should be configured for the appropriate `DelayedWETH` proxy address. All other configs should stay the same.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/012-fp-fjord-upgrade-fix/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).


## Execution

Resets the FaultDisputeGame and PermissionedDisputeGame implementations in the DGF

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Reset the FaultDisputeGame implementation in DGF


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4e392d63ae6096db5454fa178e2f8f99f8ef0ef`

### Inputs
**_impl:** `0xA4E392d63AE6096DB5454Fa178E2F8f99F8eF0ef`

**_gameType:** `0`


## Tx #2: Reset the PermissionedDisputeGame implementation in DGF


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000001000000000000000000000000864fbe13bb239521a8c837a0aa7c7122ee3eb0b2`

### Inputs
**_impl:** `0x864fbE13Bb239521a8c837A0aA7c7122ee3eb0b2`

**_gameType:** `1`

