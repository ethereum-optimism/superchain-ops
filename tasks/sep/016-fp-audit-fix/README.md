# Sepolia FP Upgrade - Granite Prestate Update

Status: READY TO SIGN

## Objective

Upgrades Fault Proof contracts to fix issues found in audits. This uses the `op-contracts/v1.6.0-rc.1` release.

## Pre-deployments (TODO)

- `FaultDisputeGame` - [`x`](https://sepolia.etherscan.io/address/x).
- `PermissionedDisputeGame` - [`x`](https://sepolia.etherscan.io/address/x).
- `AnchorStatRegistry` - [`x`](https://sepolia.etherscan.io/address/x).
- `StorageSetter` - [`0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB`](https://sepolia.etherscan.io/address/0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/013-fp-granite-prestate/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade changes the dispute game implementation of `CANNON` and `PERMISSIONED_CANNON`
game types.
This upgrade also upgrades the `AnchorStateRegistryProxy` implementation.

The batch will be executed on chain ID `11155111`, and contains `4` transactions.

See the input.json bundle for more details.
