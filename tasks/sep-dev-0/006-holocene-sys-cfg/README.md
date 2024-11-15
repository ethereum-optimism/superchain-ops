# Holocene Hardfork - Contract Upgrades

Status: DRAFT, NOT READY TO SIGN

## Objective

Upgrades the `SystemConfig` contract for the Holocene hardfork.

Contracts upgraded are included within the
[op-contracts/v1.8.0-rc.1](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.1) release.

## Pre-deployments

- `SystemConfig` - `0x29d06Ed7105c7552EFD9f29f3e0d250e5df412CD`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep-dev-0/006-holocene-sys-cfg/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes the implementation of the `SystemConfig` to hold EIP-1559 parameters for the Holocene hardfork.
* Performs the MCP L1 upgrade, setting the custom storage slots of the `SystemConfig` to protocol contract addresses.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
