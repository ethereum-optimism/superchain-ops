# Mainnet Required Protocol Version Update (7.0.0 - Fjord)

Status: DRAFT, NOT READY TO SIGN

## Objective

This is the playbook to update the required protocol version of the `ProtocolVersions` contract on Ethereum mainnet to 7.0.0 (Fjord). It is currently set to 6.0.0 (Ecotone).

This transaction should be sent on **Jul 8, 2024**, so 2 days before the Fjord mainnet activation.

The Fjord proposal was:

- [x] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236).
- [x] Approved by Token House voting [here](https://vote.optimism.io/proposals/19894803675554157870919000647998468859257602050917884642551010462863037711179).
- [ ] Not vetoed by the Citizens' house [here](https://snapshot.org/#/citizenshouse.eth/proposal/0x14336dfcb086279e47ef8fffbd6282984d392f1b9eaf22f76547210df6451c43).

The [governance proposal](https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236) should be treated as the source of truth and used to verify the correctness of the onchain operations.

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

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/012-proto-ver-required/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.
