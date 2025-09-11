# 027-U16a-opcm-upgrade-v410-base: Upgrades Base Sepolia to `op-contracts/v4.1.0` (i.e. U16a)

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Todo: Describe the objective of the task

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/027-U16a-opcm-upgrade-v410-base

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
 # https://dashboard.tenderly.co/oplabs/sepolia/simulator/7c75688d-1a8a-4929-ace9-005daa6cd9b3

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
# https://dashboard.tenderly.co/oplabs/sepolia/simulator/224344cb-326d-4a81-9344-6574b5e79af1

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
# https://dashboard.tenderly.co/oplabs/sepolia/simulator/61c228b1-3169-455f-9cbf-e04aef2bc017
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/027-U16a-opcm-upgrade-v410-base
just sign base-nested base-council 
just sign base-nested base-operations
just sign base-operations
```

Approve commands:
```bash
just approve base-nested base-council
just approve base-nested base-operations
just approve base-operations
```

Execute command: 
```
just execute
```