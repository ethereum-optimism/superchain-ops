# Guardian Changes

Status: DRAFT, NOT READY TO SIGN

## Objective

This is the playbook for reinitializing the SuperchainConfig with the Security Council as Guardian, instead of the Optimism Foundation.
This is a requirement for reaching Stage 1.

The new Guardian will be a 1/1 Safe (`0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2`) owned by the Security Council Safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`).

The proposal was:

- [X] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-guardian-security-council-threshold-and-l2-proxyadmin-ownership-changes-for-stage-1-decentralization/8157).
- [X] Approved by Token House voting [here](https://vote.optimism.io/proposals/89250535338859095270968116984279971013811713632639468811376241520756760598962).
- [ ] Not vetoed by the Citizens' house here (IN PROGRESS).
- [X] [Executed on OP Sepolia](https://github.com/ethereum-optimism/superchain-ops/tree/main/tasks/sep/006-1-guardian-upgrade).

The governance proposal should be treated as the source of truth and used to verify the correctness
of the onchain operations.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/010-1-guardian-upgrade/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [NESTED.md](../../../NESTED.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/010-1-guardian-upgrade/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
