# Security Council Safe Changes

Status: [EXECUTED](https://etherscan.io/tx/0x50db9c1b9f5a8616f982022429a1d75c35986bcfb67bd1e3358d97ddbe751144)

## Objective

This is the playbook for changes to be made to the Security Council's configuration.

There are two Safes controlled by the Security Council:

1. The Security Council Safe at `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`.
2. The 1/1 Guardian Safe owned by the Security Council at `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2`.

The following state changes will be made to those Safes:

1. On the Security Council safe, increase the threshold to at least 75% (from 4/13 to 10/13).
2. On the Security Council safe, set the `LivenessGuard` at `0x24424336F04440b1c28685a38303aC33C9D14a25`.
3. On the Security Council safe, enable the `LivenessModule` at `0x0454092516c9A4d636d3CAfA1e82161376C8a748`.
4. On the 1/1 Guardian Safe, enable the `DeputyGuardianModule` at `0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8`.

These modules are documented in the OP Stack Specification's [Security Council Safe document](https://specs.optimism.io/experimental/security-council-safe.html).

These changes are required to meet the [requirements for a Stage 1 rollup](https://medium.com/l2beat/stages-update-security-council-requirements-4c79cea8ef52).
The proposal was:

- [X] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-guardian-security-council-threshold-and-l2-proxyadmin-ownership-changes-for-stage-1-decentralization/8157).
- [X] Approved by Token House voting [here](https://vote.optimism.io/proposals/89250535338859095270968116984279971013811713632639468811376241520756760598962).
- [X] Not vetoed by the Citizens' house [here](https://snapshot.org/#/citizenshouse.eth/proposal/0x21f7126c1636cecdcf7522eadbf6e1b20ca22a2230faf871209fcd21dc999d81).
- [X] [Executed on OP Sepolia](https://github.com/ethereum-optimism/superchain-ops/tree/main/tasks/sep/006-2-sc-changes).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/010-2-sc-changes/SignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/010-2-sc-changes/SignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
