# OP Mainnet - Update L2ProxyAdmin owner to the aliased L1ProxyAdmin owner address

Status: [EXECUTED](https://optimistic.etherscan.io/tx/0x93b7a9956faec114c3bac7fd72479ebdc23f8aace38220f8914cbf6af971bf6e)

## Objective

This is the playbook for executing part of [Upgrade #8](https://gov.optimism.io/t/final-protocol-upgrade-8-guardian-security-council-threshold-and-l2-proxyadmin-ownership-changes-for-stage-1-decentralization/8157/1), to update the L2ProxyAdmin owner (L2PAO) to be the aliased L1ProxyAdmin owner (L1PAO) address, on OP Mainnet (chain ID 10).

The proposal was:

- [X] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-guardian-security-council-threshold-and-l2-proxyadmin-ownership-changes-for-stage-1-decentralization/8157).
- [X] Approved by Token House voting [here](https://vote.optimism.io/proposals/89250535338859095270968116984279971013811713632639468811376241520756760598962).
- [X] Not vetoed by the Citizens' house [here](https://snapshot.org/#/citizenshouse.eth/proposal/0x21f7126c1636cecdcf7522eadbf6e1b20ca22a2230faf871209fcd21dc999d81).
- [X] [Executed on OP Sepolia](https://github.com/ethereum-optimism/superchain-ops/tree/main/tasks/opsep/001-update-l2pao-to-aliased-l1pao).

The governance proposal should be treated as the source of truth and used to verify the correctness
of the onchain operations.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/oeth/002-update-l2pao-to-aliased-l1pao/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/oeth/002-update-l2pao-to-aliased-l1pao/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.
