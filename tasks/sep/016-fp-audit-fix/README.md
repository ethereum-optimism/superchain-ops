# Sepolia FP Upgrade - Fault Proof Audit Fixes

Status: READY TO SIGN

## Objective

Upgrades Fault Proof contracts to fix issues found in audits. This uses the `op-contracts/v1.6.0-rc.1` release.

## Pre-deployments

- `FaultDisputeGame` - [`0xD9d616E4a03a8e7cC962396C9f8D4e3d306097D3`](https://sepolia.etherscan.io/address/0xD9d616E4a03a8e7cC962396C9f8D4e3d306097D3).
- `PermissionedDisputeGame` - [`0x98E3F752c7224F8322Afa935a4CaEC3832bB25c9`](https://sepolia.etherscan.io/address/0x98E3F752c7224F8322Afa935a4CaEC3832bB25c9).
- `AnchorStatRegistry` - [`0x666D2f5316B8562e9F7B74D0B72a980E8E6F8D5C`](https://sepolia.etherscan.io/address/0x666D2f5316B8562e9F7B74D0B72a980E8E6F8D5C).
- `StorageSetter` - [`0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB`](https://sepolia.etherscan.io/address/0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/016-fp-audit-fix/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade changes the dispute game implementation of `CANNON` and `PERMISSIONED_CANNON`
game types.
This upgrade also upgrades the `AnchorStateRegistryProxy` implementation.

The batch will be executed on chain ID `11155111`, and contains `4` transactions.

See the input.json bundle for more details.
