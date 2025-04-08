# Deputy Guardian - Enable Permissioness Dispute Game

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xe5b2f3851d02e90a1ed9f6730c71d80a072ed5a340229ce39558eb5febf21f2a)

## Objective

This task updates the `respectedGameType` in the `OptimismPortalProxy` to `CANNON`, enabling users to permissionlessly propose outputs as well as for anyone to participate in the dispute of these proposals. This action requires all in-progress withdrawals to be re-proven against a new `FaultDisputeGame` that was created after this update occurs.

The batch will be executed on chain ID `11155111`, and contains `1` transactions.

## Tx #1: Update `respectedGameType` in the `OptimismPortalProxy`

Updates the `respectedGameType` to `CANNON` in the `OptimismPortalProxy`, enabling permissionless proposals and challenging.

**Function Signature:** `setRespectedGameType(address,uint32)`

**To:** `0x4220C5deD9dC2C8a8366e684B098094790C72d3c`

**Value:** `0 WEI`

**Raw Input Data:** `0xa1155ed90000000000000000000000005c1d29c6c9c8b0800692acc95d700bcb4966a1d70000000000000000000000000000000000000000000000000000000000000000`

### Inputs

**\_gameType:** `0` (`CANNON`)

**\_portal:** `0x5c1d29C6c9C8b0800692acC95D700bcb4966A1d7`

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
