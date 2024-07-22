# Base Sepolia Fault Proofs Upgrade

Status: READY TO SIGN

## Objective

This is the playbook for executing the Fault Proofs upgrade for Base on Sepolia.

1. Upgrades the `SystemConfig` proxy implementation.
2. Upgrades the `OptimismPortal` proxy implementation to use the fault proof contracts for proving and finalizing withdrawals.

## Preparing the Upgrade

The contract implementations and new proxies for the Fault Proof system have been pre-deployed to Sepolia.

| **Proxies**                |                                            |
|----------------------------|--------------------------------------------|
| `OptimismPortalProxy`      | 0x49f53e41452C74589E85cA1677426Ba426459e85 |
| `SystemConfigProxy`        | 0xf272670eb55e895584501d564AfEB048bEd26194 |
| `DisputeGameFactoryProxy`  | 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 |
| `AnchorStateRegistryProxy` | 0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205 |
| `DelayedWETHProxy`         | 0x7698b262B7a534912c8366dD8a531672deEC634e |

| **Implementations**        |                                            |
|----------------------------|--------------------------------------------|
| `OptimismPortal2`          | 0x35028bAe87D71cbC192d545d38F960BA30B4B233 |
| `SystemConfig`             | 0xCcdd86d581e40fb5a1C77582247BC493b6c8B169 |
| `DisputeGameFactory`       | 0xA51bea7E4d34206c0bCB04a776292F2f19F0BeEc |
| `FaultDisputeGame`         | 0x8A9bA50a785c3868bEf1FD4924b640A5e0ed54CF |
| `PermissionedDisputeGame`  | 0x3f5c770f17A6982d2B3Ac77F6fDC93BFE0330E17 |
| `DelayedWETH`              | 0xC0EC43cd411BdDd1161bb7491C6C8265413D2067 |
| `AnchorStateRegistry`      | 0x1ffAFb5FDc292393C187629968Ca86b112860a3e |
| `MIPS`                     | 0xFF760A87E41144b336E29b6D4582427dEBdB6dee |
| `PreimageOracle`           | 0x627F825CBd48c4102d36f287be71f4234426b9e4 |

## Signing and execution

Please see the signing and execution instructions in [SINGLE.md](../../../SINGLE.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
