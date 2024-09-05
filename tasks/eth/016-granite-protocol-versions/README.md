# Mainnet Required Protocol Version Update (8.0.0 - Granite)

Status: DRAFT, NOT READY TO SIGN

## Objective

This is the playbook to update the required and recommended protocol versions of the `ProtocolVersions` contract on Ethereum mainnet to 8.0.0 (Granite). It is currently set to 7.0.0 (Fjord).

This transaction should be sent on **Sep 9, 2024**, so 2 days before the Granite mainnet activation.

The Granite proposal was:

- [x] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733).
- [x] Approved by Token House voting [here](https://vote.optimism.io/proposals/46514799174839131952937755475635933411907395382311347042580299316635260952272).
- [ ] Not vetoed by the Citizens' house [here](https://snapshot.org/#/citizenshouse.eth/proposal/0xb0c109d7f68d3cb1054a50f55556d1820e517129b4b53774cb9ca32e0eabe3a4).
- [ ] Executed on OP Mainnet.

The [governance proposal](https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733) should be treated as the source of truth and used to verify the correctness of the onchain operations.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/012-proto-ver-required/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execution" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/016-granite-protocol-versions/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.
