# Mainnet Recommended Protocol Version Update (7.0.0 - Fjord) & Ownership Transfers

Status: DRAFT

## Objective

This is the playbook to
- Update the recommended protocol version of the `ProtocolVersions` contract on Ethereum mainnet to 7.0.0 (Fjord). It is currently set to 6.0.0 (Ecotone).
- Transfer ownership of the `ProtocolVersions` and `SystemConfig` from the `FoundationOperationsSafe` to the `FoundationUpgradeSafe` (TODO).

This transaction should be sent on **Jun 27, 2024**, so right after the Veto Period for Voting Cycle 23b has ended.

It's part of a set of transactions sent as part of the [Fjord upgrade proposal](https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236), which is currently being voted on.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/011-proto-ver+ownership-transfers/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execution" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/011-proto-ver+ownership-transfers/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.
