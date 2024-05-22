# Op Sepolia - Update L2ProxyAdmin owner to be aliased L1ProxyAdmin owner address

Status: [DRAFT]()

## Objective

This is the playbook for executing Upgrade #X, to update the L2ProxyAdmin owner (L2PAO) to be the aliased L1ProxyAdmin owner (L1PAO) address, on OP Sepolia (chain ID 11155420).

The proposal was:

- [X] Posted on the governance forum here: https://gov.optimism.io/t/upgrade-proposal-guardian-security-council-threshold-and-l2-proxyadmin-ownership-changes-for-stage-1-decentralization/8157
- [ ] Approved by Token House voting here
- [ ] Not vetoed by the Citizens' house here
- [ ] Executed on OP Sepolia

The governance proposal should be treated as the source of truth and used to verify the correctness
of the onchain operations.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/opsep/001-update-l2pao-to-aliased-l1pao/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/opsep/001-update-l2pao-to-aliased-l1pao/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.
