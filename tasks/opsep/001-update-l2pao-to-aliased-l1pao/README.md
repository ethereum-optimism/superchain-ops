# Op Sepolia - Update L2ProxyAdmin owner to be aliased L1ProxyAdmin owner address

Status: [EXECUTED](https://sepolia-optimism.etherscan.io/tx/0x06953e9fa4f05c9c074749c0d702647a67348d44f83c43948a7c8437e581f790#eventlog)

## Objective

This is the playbook for executing part of [Upgrade #8](https://gov.optimism.io/t/final-protocol-upgrade-8-guardian-security-council-threshold-and-l2-proxyadmin-ownership-changes-for-stage-1-decentralization/8157/1), to update the L2ProxyAdmin owner (L2PAO) to be the aliased L1ProxyAdmin owner (L1PAO) address, on OP Sepolia (chain ID 11155420).

Before this task was created, some OP Sepolia configuration was updated to closely mirror OP Mainnet. 
Specifically, the L2Proxy Admin owner on op-mainnet is a Safe: [0x7871d1187A97cbbE40710aC119AA3d412944e4Fe](https://optimistic.etherscan.io/address/0x7871d1187A97cbbE40710aC119AA3d412944e4Fe). On op-sepolia it was an EOA [0xfd1D2e729aE8eEe2E146c033bf4400fE75284301](https://sepolia-optimism.etherscan.io/address/0xfd1D2e729aE8eEe2E146c033bf4400fE75284301). It has since been updated to be a 1-of-1 safe: [0xb41890910b05dCba3d3dEF19B27E886C4Ab406EB](https://sepolia-optimism.etherscan.io/address/0xb41890910b05dCba3d3dEF19B27E886C4Ab406EB), where the previous L2Proxy Admin Owner EOA is it's owner.


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
