# Base Mainnet MCP L1 Upgrade

Status: [READY TO SIGN]()

## Objective

This is the playbook for executing Upgrade #6, Base Mainnet Multi-Chain Prep (MCP) L1.

The proposal was:

- [X] Posted on the governance forum here: https://gov.optimism.io/t/upgrade-proposal-6-multi-chain-prep-mcp-l1
- [X] Approved by Token House voting here: https://vote.optimism.io/proposals/47253113366919812831791422571513347073374828501432502648295761953879525315523
- [X] Not vetoed by the Citizens' house here: https://snapshot.org/#/citizenshouse.eth/proposal/0x2bc6565053b73813c6b0a001c8c07eb5656234b4d8bae12ba6541250993d1d25
- [X] Executed on OP Sepolia: https://github.com/ethereum-optimism/superchain-ops/tree/6ea64b21416917e3dfcb867fd0c76db90fb46277/tasks/sep/003-MCP-L1
- [X] Executed on OP Mainnet: https://github.com/ethereum-optimism/superchain-ops/tree/11bd3a24b3c18ccf637e32182045a377a89ec22f/tasks/eth/006-MCP-L1
- [X] Executed on Base Sepolia: https://github.com/ethereum-optimism/superchain-ops/tree/10b7011977ba239b04f18bd8499e08c616c328a5/tasks/sep/base-001-MCP-L1

The governance proposal should be treated as the source of truth and used to verify the correctness
of the onchain operations.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/eth/base-001-MCP-L1/NestedSignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

When signing as a Base signer, use `council` as the argument to the just command. 
This is actually the Base safe but the `nested.just` file uses council as a keyword and
we want to minimize changes.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [NESTED.md](../../../NESTED.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/eth/base-001-MCP-L1/NestedSignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.