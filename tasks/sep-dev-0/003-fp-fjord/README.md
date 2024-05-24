# Devnet FP Upgrade - Fjord

Upgrades the deployed system on `sepolia-devnet-0` to use the absolute prestate for the `op-program/v1.1.0` release.
The op-program release is fjord compatible.

The new dispute game implementation have been deployed against the latest deploy-config changes. This includes changes to the:
- absolute prestate
- clock extension period
- max clock duration

See https://github.com/ethereum-optimism/optimism/pull/10639 for the details.


## Pre-deployments

The `FaultDisputeGame` has been deployed at [`0x3CdB0e38bC990c07eADA1376248BB2a405Ae3B9B`](https://sepolia.etherscan.io/address/0x3CdB0e38bC990c07eADA1376248BB2a405Ae3B9B).

The `PermissionedDisputeGame` has been deployed at [`0xc06B6A93c4b8ef23e1FB535BB2dd80239ca433AC`](https://sepolia.etherscan.io/address/0xc06B6A93c4b8ef23e1FB535BB2dd80239ca433AC).

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

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000003cdb0e38bc990c07eada1376248bb2a405ae3b9b`

### Inputs
**_gameType:** `0`

**_impl:** `0x3CdB0e38bC990c07eADA1376248BB2a405Ae3B9B`


## Tx #2: Reset the PermissionedDisputeGame implementation in DGF


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x2419423C72998eb1c6c15A235de2f112f8E38efF`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c06b6a93c4b8ef23e1fb535bb2dd80239ca433ac`

### Inputs
**_gameType:** `1`

**_impl:** `0xc06B6A93c4b8ef23e1FB535BB2dd80239ca433AC`

