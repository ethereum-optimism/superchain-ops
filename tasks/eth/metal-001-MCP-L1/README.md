# Metal Mainnet MCP L1 Upgrade

Status: [EXECUTED](https://etherscan.io/tx/0x5cc6333ba2dbc12eba44db7e3f014195596d9e02ebbfc4cd718dfc0eee0d1156)

## Objective

This is the playbook for executing Upgrade #1, Metal Mainnet Multi-Chain Prep (MCP) L1.

The proposal was:

- [X] Posted on the governance forum here: https://gov.optimism.io/t/upgrade-proposal-6-multi-chain-prep-mcp-l1
- [X] Approved by Token House voting here: https://vote.optimism.io/proposals/47253113366919812831791422571513347073374828501432502648295761953879525315523
- [X] Not vetoed by the Citizens' house here: https://snapshot.org/#/citizenshouse.eth/proposal/0x2bc6565053b73813c6b0a001c8c07eb5656234b4d8bae12ba6541250993d1d25
- [X] Executed on OP Sepolia: https://github.com/ethereum-optimism/superchain-ops/tree/6ea64b21416917e3dfcb867fd0c76db90fb46277/tasks/sep/003-MCP-L1
- [X] Executed on OP Mainnet: https://github.com/ethereum-optimism/superchain-ops/tree/11bd3a24b3c18ccf637e32182045a377a89ec22f/tasks/eth/006-MCP-L1
- [X] Executed on Metal Sepolia: https://github.com/ethereum-optimism/superchain-ops/tree/57b3450cd0d870dc0c8b4d96980747eb6274e3ba/tasks/sep/metal-001-MCP-L1

The governance proposal should be treated as the source of truth and used to verify the correctness
of the onchain operations.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/eth/metal-001-MCP-L1/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/eth/metal-001-MCP-L1/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.
