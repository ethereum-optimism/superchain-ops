# Sepolia Guardian Changes - Security Council Runbook

Status: TESTFAKE

## Objective

This is the Sepolia playbook for changes to be made to the Security Council's configuration:

1. Increase its threshold to 30% (ie. from 2/10 to 3/10)
2. Enable the `LivenessGuard` at `0x8185fa3BE4608Adfae19537F75a323fe6d464a3d`.
3. Enable the `LivenessModule` at `0x9b3a60522995F90996d97a094878a7529Ff00Be1`.
4. Enable the `DeputyGuardianModule` at `0x999B254D5138D93640a40D7bDD9872a5646D0774`.

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