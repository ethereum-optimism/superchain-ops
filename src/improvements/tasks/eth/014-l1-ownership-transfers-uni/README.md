# 014-l1-ownership-transfers-uni: Transfer L1 owners for Unichain Mainnet (DGF, PermissionlessWETH and L1PAO)

Status: [READY TO SIGN]()

## Objective

Transfer the L1 owners for the Unichain Mainnet (DGF, PermissionlessWETH, PermissionedWETH and L1PAO).

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/eth/014-l1-ownership-transfers-uni
# Chain Governor Safe: 0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC 
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate chain-governor 

# Foundation Upgrade Safe: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate foundation

# Security Council: 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate council
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/eth/014-l1-ownership-transfers-uni
# Chain Governor Safe: 0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC 
just --dotenv-path $(pwd)/.env --justfile ../../../nested.just sign chain-governor 

# Foundation Upgrade Safe: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
just --dotenv-path $(pwd)/.env --justfile ../../../nested.just sign foundation

# Security Council: 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
just --dotenv-path $(pwd)/.env --justfile ../../../nested.just sign council
```