# 029-U16a-opcm-upgrade-v410-base: Upgrades Base Sepolia to `op-contracts/v4.1.0` (i.e. U16a)

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Todo: Describe the objective of the task

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/029-U16a-opcm-upgrade-v410-base

#  ┌────────────────────┐      
#  │ Child Safe Depth 2 │
#  │   'base-council'   │
#  └────────────────────┘      
#             │                
#             └─────────────────┬
#                               ▼     
#                           ┌────────────────────┐
#                           │ Child Safe Depth 1 │
#                           │    'base-nested'   │
#                           └────────────────────┘
#                                      │          
#                                      └──────────┬
#                                                 ▼
#                                          ┌─────────────────┐
#                                          │ ProxyAdminOwner │
#                                          └─────────────────┘
 SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate base-nested base-council
# https://dashboard.tenderly.co/oplabs/sepolia/simulator/d4525345-657e-4973-9cef-fe6d3fa2ff66

#  ┌────────────────────┐      
#  │ Child Safe Depth 2 │
#  │ 'base-operations'  │
#  └────────────────────┘      
#             │                
#             └─────────────────┬
#                               ▼     
#                           ┌────────────────────┐
#                           │ Child Safe Depth 1 │
#                           │    'base-nested'   │
#                           └────────────────────┘
#                                      │          
#                                      └──────────┬
#                                                 ▼
#                                          ┌─────────────────┐
#                                          │ ProxyAdminOwner │
#                                          └─────────────────┘
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate base-nested base-operations
# https://dashboard.tenderly.co/oplabs/sepolia/simulator/768b31d6-05f9-495d-b4d9-37c3ef2f4bbd

#                           ┌────────────────────┐
#                           │ Child Safe Depth 1 │
#                           │ 'base-operations'  │
#                           └────────────────────┘
#                                      │          
#                                      └──────────┬
#                                                 ▼
#                                          ┌─────────────────┐
#                                          │ ProxyAdminOwner │
#                                          └─────────────────┘
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate base-operations
# https://dashboard.tenderly.co/oplabs/sepolia/simulator/27123377-6d68-4fc5-943b-9ca405926bae
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/029-U16a-opcm-upgrade-v410-base
just sign base-nested base-council 
just sign base-nested base-operations
just sign base-operations
```

Approve commands:
```bash
# Approval for nested-nested safes
SIGNATURES=0x just approve base-nested base-council
SIGNATURES=0x just approve base-nested base-operations

# Approval for nested safes
SIGNATURES=0x just approve base-nested
SIGNATURES=0x just approve base-operations
```

Execute command: 
```
just execute
```