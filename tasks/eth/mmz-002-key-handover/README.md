# Mode, Metal, and Zora Mainnet's Key Handover Upgrade

Status: [EXECUTED](https://etherscan.io/tx/0xf4e7778523991cf6c4b305970c2c9e71ef27f652e475bb42302d582fa613f5a3)

## Objective

This is the playbook for executing the Key Handover upgrade on Mode, Metal, and Zora Mainnet.
This updates the `ProxyAdminOwner` on those chains to be the same as the OP Mainnet `ProxyAdminOwner`,
that is the [2-of-2 multisig](https://github.com/ethereum-optimism/superchain-registry/blob/d2a098074a5dc6a88f1951d1335c69c5b86970e4/superchain/configs/mainnet/op.toml#L33) jointly controlled by the Optimism Foundation and Security Council.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/tasks/eth/mmz-002-key-handover/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

### State Validations

Please see the instructions for [validation](./VALIDATION.md).

### Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/tasks/eth/mmz-002-key-handover/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown 
(without the full path), something is wrong and the safety checks will not run.