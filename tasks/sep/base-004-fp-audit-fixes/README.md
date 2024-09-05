# Base Sepolia Fault Proofs Audit Fixes Upgrade

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xc3bd572d932db4296e65db9a16876868a2a32af26810205c594e81487f4dbc90)

## Objective

This task executes the Fault Proofs audit fixes upgrade for Base on Sepolia testnet. This task:

1. Upgrades the `AnchorStateRegistry` to the newest implementation.
2. Sets the `FaultDisputeGame` implementation on the `DisputeGameFactory` to the newest implementation.
3. Sets the `PermissionedDisputeGame` implementation on the `DisputeGameFactory` to the newest implementation.

## Preparing the Upgrade

The following proxies and implementations have been deployed to Sepolia.

| **Proxies**                |                                            |
|----------------------------|--------------------------------------------|
| `DelayedWETHProxy` (FDG)   | 0x489c2E5ebe0037bDb2DC039C5770757b8E54eA1F |
| `DelayedWETHProxy` (PDG)   | 0x27A6128F707de3d99F89Bf09c35a4e0753E1B808 |

| **Implementations**        |                                            |        |
|----------------------------|--------------------------------------------| ------ |
| `FaultDisputeGame`         | 0x5062792ED6A85cF72a1424a1b7f39eD0f7972a4B | v1.3.0 |
| `PermissionedDisputeGame`  | 0xCCEfe451048Eaa7df8D0d709bE3AA30d565694D2 | v1.3.0 |
| `DelayedWETH`              | 0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538 | v1.1.0 |
| `AnchorStateRegistry`      | 0x95907b5069e5a2EF1029093599337a6C9dac8923 | v2.0.0 |
| `MIPS`                     | 0x47B0E34C1054009e696BaBAAd56165e1e994144d | v1.1.0 |
| `PreimageOracle`           | 0x92240135b46fc1142dA181f550aE8f595B858854 | v1.1.2 |
| `StorageSetter`            | 0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB | v1.2.0 |

## Signing

Please see the signing instructions in [SINGLE.md](../../../SINGLE.md).

## Execution

Please see the explanation of the task in [exec](./EXEC.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
