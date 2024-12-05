# Stage 1.4 Upgrade

Status: DRAFT, NOT READY TO SIGN

## Objective

Registers a new `FaultDisputeGame` with the `DisputeGameFactory` that is backed by the [`asterisc`][asterisc] FPVM and
the [`kona`][kona] fault proof program.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.9.0-rc.3](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.9.0-rc.3) release.

## Pre-deployments

- `RISCV` - `0x7f9a34da8d240bbe039e9f7b497c9bc500f6acf5`
- `DelayedWETHProxy` - `0x3c024f698c27a914350531bc48033e62d42703e0`
- `FaultDisputeGame` - `0xa407bc2d78cd0c8233fc0c8bf4222539730465c0`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/021-stage-1-4/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Registers the new `FaultDisputeGame` with type `3` to the `DisputeGameFactory`.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.

[asterisc]: https://github.com/ethereum-optimism/asterisc
[kona]: https://github.com/anton-rs/kona
