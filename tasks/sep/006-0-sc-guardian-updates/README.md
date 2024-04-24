# Sepolia Guardian Changes - Security Council Runbook

Status: READY TO SIGN

## Objective

This is the sepolia playbook for:

1. Finalizing the configuration of a newly deployed Security Council Safe by enabling the LivenessModule on it.
1. Removing the extra deployer key owner.

On Mainnet the threshold of the Security Council will also need to be increased, but that is not necessary here.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/sep/006-0-sc-guardian-updates/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/sep/006-0-sc-guardian-updates/SignFromJson.s.sol`. Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
