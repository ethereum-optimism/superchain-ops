# Devnet FP Upgrade - Granite 

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x7eb73a9e5eaa60aed79c09406fe5d9a890c7b7ca01839cb729e8c29cb700d161)

## Objective 

Upgrades the deployed system on `sepolia-devnet-0` to use the absolute prestate for the `op-program/v1.3.0-rc.2` release.
The op-program release is Granite compatible.

The new dispute game implementation have been deployed against the latest deploy-config changes. This includes changes to the:
- absolute prestate

See https://github.com/ethereum-optimism/optimism/pull/11371/ for the details.


## Pre-deployments

The `FaultDisputeGame` has been deployed at [`0x54416A2E28E8cbC761fbce0C7f107307991282e5`](https://sepolia.etherscan.io/address/0x54416A2E28E8cbC761fbce0C7f107307991282e5).

The `PermissionedDisputeGame` has been deployed at [`0x50573970b291726B881b204eD9F3c1D507e504cD`](https://sepolia.etherscan.io/address/0x50573970b291726B881b204eD9F3c1D507e504cD).

Both contracts have been configured using the aforementioned deploy-config.


## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

# Reset DisputeGameFactory game implementations
Resets the FaultDisputeGame and PermissionedDisputeGame implementations in the DGF

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Reset the FaultDisputeGame implementation in DGF


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x2419423C72998eb1c6c15A235de2f112f8E38efF`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000054416A2E28E8cbC761fbce0C7f107307991282e5`

### Inputs
**_gameType:** `0`

**_impl:** `0x54416A2E28E8cbC761fbce0C7f107307991282e5`


## Tx #2: Reset the PermissionedDisputeGame implementation in DGF


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x2419423C72998eb1c6c15A235de2f112f8E38efF`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000100000000000000000000000050573970b291726B881b204eD9F3c1D507e504cD`

### Inputs
**_gameType:** `1`

**_impl:** `0xc06B6A93c4b8ef23e1FB535BB2dd80239ca433AC`
