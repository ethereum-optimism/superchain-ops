# Holocene Hardfork Upgrade - `SystemConfig`

Status: READY TO SIGN

## Objective

Upgrades the `SystemConfig` for the Holocene hardfork for Sepolia/{OP,Mode,Metal,Zora,Base}

The proposal was:

- [ ] Posted on the governance forum.
- [ ] Approved by Token House voting.
- [ ] Not vetoed by the Citizens' house.
- [ ] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

Governance post of the upgrade can be found at <placeholder>.

This upgrades the `SystemConfig` in the
[op-contracts/v1.8.0](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.1) release.

## Pre-deployments

- `SystemConfig` - `0x29d06Ed7105c7552EFD9f29f3e0d250e5df412CD`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/<path>/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes the implementation of the `SystemConfig` to hold EIP-1559 parameters for the

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
