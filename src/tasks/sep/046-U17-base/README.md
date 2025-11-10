# 046-U17-base: Upgrades Base Sepolia to `op-contracts/v5.0.0` (i.e. U17)

Status: [READY TO SIGN]

## Objective

Upgrade Base Sepolia to U17. More context on U17 can be found in the Optimism docs.

The [VALIDATION.md](./VALIDATION.md) file contains the calldata and various hashes for this task.

## Simulation, Signing & Execution

Below you can find the steps to complete the execution of this transaction. Base has a doubly-nested safe architecture which is supported by superchain-ops.
You **MUST** ensure the hashes you generate from running the commands below match the documented hashes. If you notice *any* mismatches, please alert your facilitator **immediately**.

```bash
#
#    ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐
#    │                 Base Council                │       │              Base Operations                │       │              Base Operations                │ 
#    │                  (3 of 14)                  │       │                 (1 of 14)                   │       │                 (1 of 14)                   │
#    │  0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f │       │  0x6AF0674791925f767060Dd52f7fB20984E8639d8 │       │  0x6AF0674791925f767060Dd52f7fB20984E8639d8 │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │                                                     │
#                          └─────────────────┬───────────────────────────────────┘                                                     │      
#                                            ▼                                                                                         │
#                             ┌─────────────────────────────────────────────┐                                                          │
#                             │                 Base Nested                 │                                                          │
#                             │  0x646132A1667ca7aD00d36616AFBA1A28116C770A │                                                          │
#                             └─────────────────────┬───────────────────────┘                                                          │
#                                                   │                                                                                  │
#                                                   └─────────────────┬────────────────────────────────────────────────────────────────┘
#                                                                     ▼
#                                            ┌─────────────────────────────────────────────┐
#                                            │               ProxyAdminOwner               │
#                                            │  0x0fe884546476dDd290eC46318785046ef68a0BA9 │
#                                            └─────────────────────────────────────────────┘
```

### Step 1 (Role: Signer) - Base Nested Simulation and Signing

In this section, through a sequence of commands, we will successfully sign this task’s upgrade transaction from the 'base-nested' (`0x646132A1667ca7aD00d36616AFBA1A28116C770A`) safe. 

```bash
cd src/tasks/sep/044-U17-sep-base

# Base Council: 0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f
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
# Expected Hashes
# Domain Hash: 0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23
# Message Hash: 0xb3fe0a134286bb6386c1224eeba2430a8fc6578a68303223338dbfec538c4f45

# Base Operations: 0x6AF0674791925f767060Dd52f7fB20984E8639d8
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
# Expected Hashes
# Domain Hash: 0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa
# Message Hash: 0xd864a7823d1209dfb3879f5cc42f3196c458452c1236d1b58d4128138309c331
```

Now, perform the signing for both safes that are owners of 'base-nested':
```bash
cd src/tasks/sep/046-U17-base

just --dotenv-path $(pwd)/.env sign base-nested base-council 
# Expected Hashes
# Domain Hash: 0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23
# Message Hash: 0xb3fe0a134286bb6386c1224eeba2430a8fc6578a68303223338dbfec538c4f45

just --dotenv-path $(pwd)/.env sign base-nested base-operations
# Expected Hashes
# Domain Hash: 0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa
# Message Hash: 0xd864a7823d1209dfb3879f5cc42f3196c458452c1236d1b58d4128138309c331
```

> **⚠️ Attention Signers:**
> Once you've signed, please send your signatures to the designated ceremony facilitator.

> **⚠️ Attention Base Operations Signers (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`):**
> **ONLY Base Operations signers MUST continue to Step 1a**. You must provide another signature because the base-operations safe is used twice in Base’s Sepolia safe architecture. 

### Step 1a (Role: Base Operations Signer) - Base Operations Simulation and Signing

The Base Operations Safe (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`) executes two 'approveHash' transactions in this ceremony. Therefore, to pre-commit to the correct hashes, we need to increment the nonce of the Base Operations Safe in the [config.toml](./config.toml) file. 

Your [config.toml](./config.toml) file **MUST** match the data below:
```toml
[stateOverrides]
# Base Sepolia ProxyAdminOwner
0x0fe884546476dDd290eC46318785046ef68a0BA9 = [
     {key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 26}
]
# Base Nested Safe
0x646132A1667ca7aD00d36616AFBA1A28116C770A = [ 
     {key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 9}
]
# Base Council Safe
0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f = [ 
     {key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 10}
]
# Base Operations Safe
0x6AF0674791925f767060Dd52f7fB20984E8639d8 = [ 
     {key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 15} # <--- THIS IS THE ONLY CHANGE
]
```

Once you've updated the nonce for the base-operations safe, you can now safely simulate and sign:

```bash
# Base Operations: 0x6AF0674791925f767060Dd52f7fB20984E8639d8
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
# Expected Hashes
# Domain Hash: 0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa
# Message Hash: 0x33562e40883b96b77bb83390e16f0a2872cb34ff0b6df979c42b0679b29a9d78

just --dotenv-path $(pwd)/.env sign base-operations
# Expected Hashes
# Domain Hash: 0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa
# Message Hash: 0x33562e40883b96b77bb83390e16f0a2872cb34ff0b6df979c42b0679b29a9d78
```

### Step 2 (Role: Facilitator) - Base Nested Approval

After receiving each signer’s signatures from Step 1, you must use them to make the necessary 'approveHash' calls. In this section, there are a total of 3 'approveHash' calls.
```bash

#  .------------.               .-----------.
#  |base-council|               |base-nested|
#  '------------'               '-----------'
#        |                            |      
#        |Execute approveHash(bytes32)|      
#        |--------------------------->|      
#  .------------.               .-----------.
#  |base-council|               |base-nested|
#  '------------'               '-----------'
# You can read this command as, call approveHash on 'base-nested' from 'base-council'.
# For the 'base-council' to successfully execute the approveHash transaction, it needs a quorum of signatures from signers.
SIGNATURES=0x<concatenated-sigs-from-base-council-members> just approve base-nested base-council

# .---------------.              .-----------.
# |base-operations|              |base-nested|
# '---------------'              '-----------'
#         |                            |      
#         |Execute approveHash(bytes32)|      
#         |--------------------------->|      
# .---------------.              .-----------.
# |base-operations|              |base-nested|
# '---------------'              '-----------'
# You can read this command as, call approveHash on 'base-nested' from 'base-operations'.
# For the 'base-operations' to successfully execute the approveHash transaction, it needs a quorum of signatures from signers.
# The signatures below MUST be from 'Step 1' NOT 'Step 1a'.
SIGNATURES=0x<concatenated-sigs-from-base-operations-members-step1> just approve base-nested base-operations 

# .-----------.             .-----------------.
# |base-nested|             |proxy-admin-owner|
# '-----------'             '-----------------'
#       |                            |         
#       |Execute approveHash(bytes32)|         
#       |--------------------------->|         
# .-----------.             .-----------------.
# |base-nested|             |proxy-admin-owner|
# '-----------'             '-----------------'
# You can read this command as, call approveHash on ProxyAdminOwner from 'base-nested'.
# We don't need to pass through 'SIGNATURES' here because this transaction was pre-approved in the previous two steps.
just approve base-nested
```

### Step 3 (Role: Facilitator) - Base Operations Approval

This is the final 'approveHash' call from the base-operations safe.

```bash
# .---------------.           .-----------------.
# |base-operations|           |proxy-admin-owner|
# '---------------'           '-----------------'
#         |                            |         
#         |Execute approveHash(bytes32)|         
#         |--------------------------->|         
# .---------------.           .-----------------.
# |base-operations|           |proxy-admin-owner|
# '---------------'           '-----------------'
# You can read this command as, call approveHash on ProxyAdminOwner from 'base-operations'.
# The signatures below MUST be from 'Step 1a' NOT 'Step 1'.
SIGNATURES=0x<concatenated-sigs-from-base-operations-members-step1a> just approve base-operations 
```

### Step 4 (Role: Facilitator) - Execute Transaction on L1 ProxyAdminOwner `0x0fe884546476dDd290eC46318785046ef68a0BA9`

Execute command: 
```bash
cd src/tasks/sep/046-U17-base
just --dotenv-path $(pwd)/.env execute
```
