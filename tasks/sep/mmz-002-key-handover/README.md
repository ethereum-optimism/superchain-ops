# Mode, Metal, and Zora Sepolia's Key Handover Upgrade

Status: READY TO SIGN

## Objective

This is the playbook for executing the Key Handover upgrade on Mode, Metal, and Zora Sepolia.
This updates the `ProxyAdminOwner` to the same ProxyAdmin owner multisig account as OP Sepolia account.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/tasks/sep/mmz-002-key-handover/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

### State Validations

Please see the instructions for [validation](./VALIDATION.md).

### Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/tasks/sep/mmz-002-key-handover/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown 
(without the full path), something is wrong and the safety checks will not run.
