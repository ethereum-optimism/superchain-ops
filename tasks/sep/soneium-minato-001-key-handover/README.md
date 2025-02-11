# Soneium Minato Sepolia's Key Handover Upgrade

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x22779d95be4a2578bf50c388e0be577bff7124a8f2dc55be3b6c5a1dcfcb0565)

## Objective

This is the playbook for executing the Key Handover upgrade on Soneium Minato Sepolia.
This updates the `ProxyAdminOwner` to the same ProxyAdmin owner multisig account as OP Sepolia account.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/tasks/sep/soneium-minato-001-key-handover/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

### State Validations

Please see the instructions for [validation](./VALIDATION.md).

### Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/tasks/sep/soneium-minato-001-key-handover/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown 
(without the full path), something is wrong and the safety checks will not run.