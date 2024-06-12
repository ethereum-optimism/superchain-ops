# Mainnet Fjord Fault Proofs Upgrade

Status: DRAFT

## Objective

This is a playbook for upgrading Fault Proofs on Mainnet for Fjord compatibility.

This sets the `FaultDisputeGame` and `PermissionedDisputeGame` implementations in the `DisputeGameFactory` to newly deployed contracts that have an updated prestate.

Governance post of the upgrade can be found at https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236.

Details on the upgrade procedure can be found in [EXEC.md](./EXEC.md). Signers need not validate the, but they are provided for reference.

## Preparing the Upgrade

The new Fault Dispute Game coontract implementations have been pre-deployed to mainnet.

- `FaultDisputeGame`: [`0xf691F8A6d908B58C534B624cF16495b491E633BA`](https://etherscan.io/address/0xc307e93a7C530a184c98EaDe4545a412b857b62f)
- `PermissionedDisputeGame` - [`0xc307e93a7C530a184c98EaDe4545a412b857b62f`](https://etherscan.io/address/0xc307e93a7C530a184c98EaDe4545a412b857b62f)

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/013-fp-upgrade-fjord/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## Signing and execution

Please see the signing and execution instructions in [NESTED.md](../../../NESTED.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
