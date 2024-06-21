# Sepolia Guardian Changes - Security Council Runbook

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xc369539475c779729adb1ae9326e9245cefccdb0159cabc2f0be7650c6cfe170)

## Objective

This is the Sepolia playbook for changes to be made to the Security Council's configuration.

There are two Safes controlled by the Security Council:

1. The Security Council Safe at `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`.
2. The 1/1 Guardian Safe owned by the Security Council at `0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E`.

The following state changes will be made to those Safes:

1. On the Security Council safe, increase the threshold to 30% (from 2/10 to 3/10)
2. On the Security Council safe, set the `LivenessGuard` at `0xc26977310bC89DAee5823C2e2a73195E85382cC7`.
3. On the Security Council safe, enable the `LivenessModule` at `0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e`.
4. On the 1/1 Guardian Safe, enable the `DeputyGuardianModule` at `0x4220C5deD9dC2C8a8366e684B098094790C72d3c`.

These modules are documented in the OP Stack Specification's [Security Council Safe document](https://specs.optimism.io/experimental/security-council-safe.html).

The threshold change is intended to simulate a similar change which will occur on Mainnet, which will increase the Security Council's threshold
to 75% in order to meet the [requirements for a Stage 1 rollup](https://medium.com/l2beat/stages-update-security-council-requirements-4c79cea8ef52).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/006-2-sc-changes/SignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/006-2-sc-changes/SignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
