# 029-U16a-opcm-upgrade-v410-base: Upgrades Base Sepolia to `op-contracts/v4.1.0` (i.e. U16a)

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x5abbe161ffecb01535c1e9881023fa9f8fdd8fc1c5e92507a816fe245fafae9d)

## Objective

Upgrade Base Sepolia to U16a. More context on U16a can be found in the Optimism docs [here](https://docs.optimism.io/notices/upgrade-16a).

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
cd src/improvements/tasks/sep/029-U16a-opcm-upgrade-v410-base

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
# Message Hash: 0x2101962158503cfe04f7fc3fb3db310076c262dd27acc4a1922b03b723d9da80
# Normalized Hash: 0x2b3f64abf5d23abe68d847d53532878885af39d26ddf432293ba93a2a9a56b4d

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
# Message Hash: 0x8b952db91f6bd118dcc0c011d1dc6965fb754f6cbf7c8dc6c565bef31dab4c81
# Normalized Hash: 0x2b3f64abf5d23abe68d847d53532878885af39d26ddf432293ba93a2a9a56b4d
```

Now, perform the signing for both safes that are owners of 'base-nested':
```bash
cd src/improvements/tasks/sep/029-U16a-opcm-upgrade-v410-base

just --dotenv-path $(pwd)/.env sign base-nested base-council 
# Expected Hashes
# Domain Hash: 0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23
# Message Hash: 0x2101962158503cfe04f7fc3fb3db310076c262dd27acc4a1922b03b723d9da80
# Normalized Hash: 0x2b3f64abf5d23abe68d847d53532878885af39d26ddf432293ba93a2a9a56b4d

just --dotenv-path $(pwd)/.env sign base-nested base-operations
# Expected Hashes
# Domain Hash: 0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa
# Message Hash: 0x8b952db91f6bd118dcc0c011d1dc6965fb754f6cbf7c8dc6c565bef31dab4c81
# Normalized Hash: 0x2b3f64abf5d23abe68d847d53532878885af39d26ddf432293ba93a2a9a56b4d
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
     {key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 24}
]
# Base Nested Safe
0x646132A1667ca7aD00d36616AFBA1A28116C770A = [ 
     {key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 7}
]
# Base Council Safe
0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f = [ 
     {key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 4}
]
# Base Operations Safe
0x6AF0674791925f767060Dd52f7fB20984E8639d8 = [ 
     {key = "0x0000000000000000000000000000000000000000000000000000000000000005", value = 11} # <--- THIS IS THE ONLY CHANGE
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
# Message Hash: 0x1efd160c418041038c6a9e0396ed887fdbbf6f11aef6aa0f93a527fb9a8b95d9
# Normalized Hash: 0x2b3f64abf5d23abe68d847d53532878885af39d26ddf432293ba93a2a9a56b4d

just --dotenv-path $(pwd)/.env sign base-operations
# Expected Hashes
# Domain Hash: 0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa
# Message Hash: 0x1efd160c418041038c6a9e0396ed887fdbbf6f11aef6aa0f93a527fb9a8b95d9
# Normalized Hash: 0x2b3f64abf5d23abe68d847d53532878885af39d26ddf432293ba93a2a9a56b4d
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
cd src/improvements/tasks/sep/029-U16a-opcm-upgrade-v410-base
just --dotenv-path $(pwd)/.env execute
```
