# {Chain Name i.e. Base Mainnet} Key Handover Upgrade

Status: READY TO SIGN

## Objective

This is the playbook for executing the Key Handover upgrade on {Chain Name i.e. Base Mainnet}.
This updates the `ProxyAdminOwner` on those chains to be the same as the OP Mainnet `ProxyAdminOwner`,
that is the [2-of-2 multisig](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/op.toml#L33) jointly controlled by the Optimism Foundation and Security Council.

OR for testnets:

This is the playbook for executing the Key Handover upgrade on {Chain Name i.e. Base Mainnet}.
This updates the `ProxyAdminOwner` to the same ProxyAdmin owner multisig account as OP Sepolia account.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/<NETWORK_DIR>/<RUNBOOK_DIR>/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

### State Validations

Please see the instructions for [validation](./VALIDATION.md).

### Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/<NETWORK_DIR>/<RUNBOOK_DIR>/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown 
(without the full path), something is wrong and the safety checks will not run.
