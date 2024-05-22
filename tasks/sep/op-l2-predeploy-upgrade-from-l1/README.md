# Sepolia Upgrade L2 Predeploy From L1

Status: [DRAFT]()

## Objective

This is the Sepolia playbook for performing an L2 predeploy upgrade using the L1 Proxy Admin Owner. The exact upgrade will be a no-op, meaning we will upgrade a predeploy to the same implementation address it is already pointing to. This approach will allow us to confirm that predeploy upgrades on L2 work using a transaction originating from L1.
Ultimately, having the security council have veto power over L2 predeploy upgrades is a requirement for reaching Stage 1. The security council is a signer on the L1 Proxy Admin Owner.

The success criteria involve verifying that the dummy upgrade occurred on L2 and, prior to this, confirming that a `TransactionDeposited` event was emitted from the `OptimismPortal` on L1.


## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/op-l2-predeploy-upgrade-from-l1/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [NESTED.md](../../../NESTED.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/sep/op-l2-predeploy-upgrade-from-l1/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
