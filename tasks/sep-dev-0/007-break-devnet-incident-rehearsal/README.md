# Sepolia Devnet - Incident Rehearsal

Status: DRAFT, NOT READY TO SIGN

## Objective

Upgrades the `FaultDisputeGame` contract to a version with an ***invalid*** prestate, for the sake of creating a mock
incident on the internal Sepolia devnet. As part of resolving this incident, the old implementation contract will
be restored.

## Pre-deployments

- Misconfigured `FaultDisputeGame` - `0xb99208cd3fd55cae2bb0e47dd8e2337d88841bbd`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep-dev-0/007-break-devnet-incident-rehearsal/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes the implementation of the `SystemConfig` to hold EIP-1559 parameters for the Holocene hardfork.
* Performs the MCP L1 upgrade, setting the custom storage slots of the `SystemConfig` to protocol contract addresses.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
