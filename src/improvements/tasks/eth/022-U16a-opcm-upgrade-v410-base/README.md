# 022-U16a-opcm-upgrade-v410-base: Upgrades Base Mainnet to `op-contracts/v4.1.0` (i.e. U16a)

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrade Base Mainnet to U16a. More context on U16a can be found in the Optimism docs [here](https://docs.optimism.io/notices/upgrade-16a).

## Simulation, Signing & Execution

Below you can find the steps to complete the execution of this transaction. Base has a doubly-nested safe architecture which is supported by superchain-ops. 
You **MUST** ensure the hashes you generate from running the commands below match the documented hashes. If you notice *any* mismatches, please alert your facilitator **immediately**.

```bash
#
#    ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐
#    │                 Base Council                │       │              Base Operations                │       │           Foundation Operations (FOS)       │ 
#    │                  (7 of 10)                  │       │                 (3 of 6)                    │       │                 (5 of 7)                    │
#    │  0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd │       │  0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110 │       │  0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │                                                     │
#                          └─────────────────┬───────────────────────────────────┘                                                     │      
#                                            ▼                                                                                         │
#                             ┌─────────────────────────────────────────────┐                                                          │
#                             │                 Base Nested                 │                                                          │
#                             │  0x9855054731540A48b28990B63DcF4f33d8AE46A1 │                                                          │
#                             └─────────────────────┬───────────────────────┘                                                          │
#                                                   │                                                                                  │
#                                                   └─────────────────┬────────────────────────────────────────────────────────────────┘
#                                                                     ▼
#                                            ┌─────────────────────────────────────────────┐
#                                            │               ProxyAdminOwner               │
#                                            │  0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c │
#                                            └─────────────────────────────────────────────┘
```


### Step 1 (Role: Signer) - Base Nested Simulation and Signing

In this section, you will simulate and sign the upgrade transactions for the 'base-nested' (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`) path and the 'foundation-operations' (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`) path. Both of these safes are required to reach a threshold on the Proxy Admin Owner.

```bash
cd src/improvements/tasks/eth/022-U16a-opcm-upgrade-v410-base

# Base Council: 0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd
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
# Domain Hash: 0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3
# Message Hash: 0x520aeeb85997f9db884ae07d1da74b5251550f49ab662b9ada3fa34572ece772
# Normalized Hash: 0x1040a2a57a0fc30a1ff18d3c0e35898dbf98c89dc172945b99a0f3b65508c659

# Base Operations: 0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110
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
# Domain Hash: 0xfb308368b8deca582e84a807d31c1bfcec6fda754061e2801b4d6be5cb52a8ac
# Message Hash: 0x5ae6e3b8fe66bd6cbe5fae6374222b43a874c13ca850745926ecc430cafdb21a
# Normalized Hash: 0x1040a2a57a0fc30a1ff18d3c0e35898dbf98c89dc172945b99a0f3b65508c659


# Foundation Operations: 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
#                           ┌────────────────────┐
#                           │ Child Safe Depth 1 │
#                           │        'FOS'       │
#                           └────────────────────┘
#                                      │          
#                                      └──────────┬
#                                                 ▼
#                                          ┌─────────────────┐
#                                          │ ProxyAdminOwner │
#                                          └─────────────────┘
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate foundation-operations
# Expected Hashes
# Domain Hash: 0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890
# Message Hash: 0x2b7f17c0100e6766aaac289acba0122860a51bdd64810626948b0f986f88efa5
# Normalized Hash: 0x1040a2a57a0fc30a1ff18d3c0e35898dbf98c89dc172945b99a0f3b65508c659
```

Now, perform the signing for both safes that are owners of 'base-nested':
```bash
cd src/improvements/tasks/eth/022-U16a-opcm-upgrade-v410-base

just --dotenv-path $(pwd)/.env sign base-nested base-council 
# Expected Hashes
# Domain Hash: 0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3
# Message Hash: 0x520aeeb85997f9db884ae07d1da74b5251550f49ab662b9ada3fa34572ece772
# Normalized Hash: 0x1040a2a57a0fc30a1ff18d3c0e35898dbf98c89dc172945b99a0f3b65508c659

just --dotenv-path $(pwd)/.env sign base-nested base-operations
# Expected Hashes
# Domain Hash: 0xfb308368b8deca582e84a807d31c1bfcec6fda754061e2801b4d6be5cb52a8ac
# Message Hash: 0x5ae6e3b8fe66bd6cbe5fae6374222b43a874c13ca850745926ecc430cafdb21a
# Normalized Hash: 0x1040a2a57a0fc30a1ff18d3c0e35898dbf98c89dc172945b99a0f3b65508c659


just --dotenv-path $(pwd)/.env sign foundation-operations
# Expected Hashes
# Domain Hash: 0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890
# Message Hash: 0x2b7f17c0100e6766aaac289acba0122860a51bdd64810626948b0f986f88efa5
# Normalized Hash: 0x1040a2a57a0fc30a1ff18d3c0e35898dbf98c89dc172945b99a0f3b65508c659
```

> **⚠️ Attention Signers:**
> Once you've signed, please send your signatures to the designated ceremony facilitator.

### Step 2 (Role: Facilitator) - Base Nested Approval

After receiving each signer's signature from Step 1, you must use them to make the necessary 'approveHash' calls. In this section, there are a total of 3 'approveHash' calls.
```bash
cd src/improvements/tasks/eth/022-U16a-opcm-upgrade-v410-base

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
SIGNATURES=0x<concatenated-sigs-from-base-operations-members> just approve base-nested base-operations 

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

### Step 3 (Role: Facilitator) - Foundation Operations Approval

This is the final 'approveHash' call from the foundation-operations safe.

```bash
cd src/improvements/tasks/eth/022-U16a-opcm-upgrade-v410-base
# .---------------.           .-----------------.
# |     FOS       |           |proxy-admin-owner|
# '---------------'           '-----------------'
#         |                            |         
#         |Execute approveHash(bytes32)|         
#         |--------------------------->|         
# .---------------.           .-----------------.
# |     FOS       |           |proxy-admin-owner|
# '---------------'           '-----------------'
# You can read this command as, call approveHash on ProxyAdminOwner from 'foundation-operations'.
SIGNATURES=0x<concatenated-sigs-from-foundation-operations-members> just approve foundation-operations
```

### Step 4 (Role: Facilitator) - Execute Transaction on L1 ProxyAdminOwner `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`

Execute command: 
```bash
cd src/improvements/tasks/eth/022-U16a-opcm-upgrade-v410-base
just --dotenv-path $(pwd)/.env execute
```
