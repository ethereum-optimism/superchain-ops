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
SIMULATE_WITHOUT_LEDGER=1 just simulate base-nested base-council 

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
SIMULATE_WITHOUT_LEDGER=1 just simulate base-nested base-operations
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/027-U16a-opcm-upgrade-v410-base
just sign base-nested base-council 
just sign base-nested base-operations
```

Approve commands:
```bash
just approve base-nested base-council
just approve base-nested base-operations
```

Execute command: 
```
just execute
```