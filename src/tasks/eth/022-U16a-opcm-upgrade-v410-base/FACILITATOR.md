# 022-U16a-opcm-upgrade-v410-base: Upgrades Base Mainnet to `op-contracts/v4.1.0` (i.e. U16a)

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrade Base Mainnet to U16a. More context on U16a can be found in the Optimism docs [here](https://docs.optimism.io/notices/upgrade-16a).

This document is solely for the upgrade Facilitator. If you are a signer on the Base Council, Base Operations, or Foundations Operations, please, instead, follow the instructions [here](./README.md).

## Step 1 - Base Nested Approval

After receiving each signer's signature from the instructions [here](./README.md), you must use them to make the necessary 'approveHash' calls. In this section, there are a total of 3 'approveHash' calls.
```bash
cd src/tasks/eth/022-U16a-opcm-upgrade-v410-base

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

## Step 2 - Foundation Operations Approval

This is the final 'approveHash' call from the foundation-operations safe.

```bash
cd src/tasks/eth/022-U16a-opcm-upgrade-v410-base
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

## Step 3 - Execute Transaction on L1 ProxyAdminOwner `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`

Execute command: 
```bash
cd src/tasks/eth/022-U16a-opcm-upgrade-v410-base
just --dotenv-path $(pwd)/.env execute
```
