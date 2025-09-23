# DelayedWETH Ownership Transfer - OP Mainnet

Status: [EXECUTED](https://etherscan.io/tx/0x0fa256d2f49d9bf94abf6bfcd3defcbb29dcd2edeb1e3750a68c3fa7993aea95)

## Objective

Transfers ownership of the `DelayedWETH` contracts for the `PermissionedDisputeGame` and
`FaultDisputeGame` from the Foundation Operations Safe to the `ProxyAdmin` owner address.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/src/improvements/template/DelayedWETHOwnershipTemplate.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade:

- Transfers ownership of the `DelayedWETH` contracts for the `PermissionedDisputeGame` and
`FaultDisputeGame` from the Foundation Operations Safe to the `ProxyAdmin` owner address.
