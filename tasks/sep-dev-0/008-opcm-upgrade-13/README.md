# Holocene Hardfork Upgrade - `SystemConfig`

Status: READY TO SIGN

## Objective


## Pre-deployments

- `OPContractsManager` - ``

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/027-holocene-system-config-upgrade-and-init-multi-chain/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade upgrades the implementation of the `SystemConfig` implementation on multiple chains and reinitializes each of the in such a way as to preserve the semantics of all existing parameters stored in that contract.

The batch will be executed on L1 chain ID `11155111`, and contains  `3n` transactions, where `n=4` is the number of L2 chains being upgraded. The chains affected are {op,metal,mode,zora}-sepolia.

The below is a summary of the transaction bundle, see `input.json` for full details.

