# 015-transfer-l2pao-uni: Transfer L2PAO to the owner defined in standard configuration.

Status: [READY TO SIGN]()

## Objective

Transfer the L2PAO to the owner defined in the standard configuration. For this task, it means transferring the L2PAO to the aliaed L1PAO i.e. `alias(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` => `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` (aliased) via a deposit transaction.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/eth/015-transfer-l2pao-uni

# Chain Governor Safe: 0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC 
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate chain-governor 

# Foundation Upgrade Safe: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate foundation

# Security Council: 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate council
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/eth/015-transfer-l2pao-uni

# Chain Governor Safe: 0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC 
just --dotenv-path $(pwd)/.env --justfile ../../../nested.just sign chain-governor 

# Foundation Upgrade Safe: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
just --dotenv-path $(pwd)/.env --justfile ../../../nested.just sign foundation

# Security Council: 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
just --dotenv-path $(pwd)/.env --justfile ../../../nested.just sign council
```

## Approval and Execution Instructions

You can find the approval and execution instructions in the [NESTED.md](../../../NESTED.md) file.