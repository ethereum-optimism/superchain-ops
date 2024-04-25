# Sepolia Guardian Changes - Security Council Runbook

Status: TESTFAKE

## Objective

This is the Sepolia playbook for changes to be made to the Security Council's configuration:

1. Increase its threshold to 30% (ie. from 2/10 to 3/10)
2. Enable the `LivenessGuard` at `0x4416c7Fe250ee49B5a3133146A0BBB8Ec0c6A321`.
3. Enable the `LivenessModule` at `0x812B1fa86bE61a787705C49fc0fb05Ef50c8FEDf`.
4. Enable the `DeputyGuardianModule` at `0xed12261735aD411A40Ea092FF4701a962d25cA21`.

<!-- TODO ^ Replace the TestFake addresses above with the final FAKE addresses -->

These modules are documented in the OP Stack Specification's [Security Council Safe document](https://github.com/ethereum-optimism/specs/blob/b8580f28d1371b24461d4fd08e02763c2a5b66f5/specs/experimental/security-council-safe.md#L1).

The threshold change is intended to simulate a similar change which will occur on Mainnet, which will increase the Security Council's threshold
to 75% in order to meet the [requirements for a Stage 1 rollup](https://medium.com/l2beat/stages-update-security-council-requirements-4c79cea8ef52).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/006-0-sc-changes/SignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/006-0-sc-changes/SignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
