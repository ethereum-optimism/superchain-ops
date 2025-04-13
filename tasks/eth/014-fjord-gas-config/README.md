# Mainnet Gas Config Update for Fjord

Status: [EXECUTED](https://etherscan.io/tx/0x220c443aebcd9bb04d6eb79e975c6bbe710104feddf8c4fffa3f13eb3c338af9)

## Objective

This is the playbook to update the gas scalar configuration on the `SystemConfig` contract for OP Mainnet.
Fjord uses the same configuration parameters as Ecotone, that is, the _base fee_ and _blob base fee scalars_.
Because [Fjord updates the L1 cost function to be based on a compression estimation using FastLZ](https://github.com/ethereum-optimism/specs/blob/main/specs/protocol/fjord/exec-engine.md#fees),
these scalars have to be adjusted.
Details on the transaction input can be found in the validation file, see below.

This transaction should be sent within five minutes of the successful Fjord mainnet activation on **Jul 10, 16:00:01 UTC**.

The Fjord proposal was:

- [x] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236).
- [x] Approved by Token House voting [here](https://vote.optimism.io/proposals/19894803675554157870919000647998468859257602050917884642551010462863037711179).
- [x] Not vetoed by the Citizens' house [here](https://snapshot.org/#/citizenshouse.eth/proposal/0x14336dfcb086279e47ef8fffbd6282984d392f1b9eaf22f76547210df6451c43).

The [governance proposal](https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236) should be treated as the source of truth and used to verify the correctness of the onchain operations.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/014-fjord-gas-config/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execution" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/014-fjord-gas-config/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.
