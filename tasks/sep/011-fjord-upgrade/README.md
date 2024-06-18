# Sepolia FP Upgrade - Fjord

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x68178d475add97b2ec1ec7dc02056c7c364d4458c3eabec8875fe91ab8a141a7)

## Objective

Upgrades the deployed system on `sepolia` to use the absolute prestate for the `op-program/v1.1.0` release.
The op-program release is fjord compatible.

See https://github.com/ethereum-optimism/optimism/pull/10666 for the updated deploy configuration.

## Pre-deployments

The `FaultDisputeGame` has been deployed at [`0x3BC41c5206DF07C842a850818FFb94796d42313D`](https://sepolia.etherscan.io/address/0x3BC41c5206DF07C842a850818FFb94796d42313D).

The `PermissionedDisputeGame` has been deployed at [`0x848e6Ff026A56e75A1137f89f6286d14789997Bc`](https://sepolia.etherscan.io/address/0x848e6Ff026A56e75A1137f89f6286d14789997Bc).

Both contracts have been configured using the aforementioned deploy-config.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).


## Execution

Resets the FaultDisputeGame and PermissionedDisputeGame implementations in the DGF.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

### Tx #1: Reset the FaultDisputeGame implementation in DGF


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bc41c5206df07c842a850818ffb94796d42313d`

#### Inputs
**_gameType:** `0`

**_impl:** `0x3BC41c5206DF07C842a850818FFb94796d42313D`


### Tx #2: Reset the PermissionedDisputeGame implementation in DGF


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000001000000000000000000000000848e6ff026a56e75a1137f89f6286d14789997bc`

#### Inputs
**_impl:** `0x848e6Ff026A56e75A1137f89f6286d14789997Bc`

**_gameType:** `1`
