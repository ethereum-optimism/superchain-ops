# Mainnet Multichain Upgrade

## Objective

This is meant to upgrade the L1 smart contracts to the multichain release.

The following table contains the Proxy addresses used by OP Mainnet that are
impacted by the upgrade.

| Contract (Proxies)           | Address                                    |
|------------------------------|--------------------------------------------|
| L1CrossDomainMessenger       | [0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1](https://etherscan.io/address/0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1) |
| L1ERC721Bridge               | [0x5a7749f83b81B301cAb5f48EB8516B986DAef23D](https://etherscan.io/address/0x5a7749f83b81B301cAb5f48EB8516B986DAef23D) |
| L1StandardBridge             | [0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1](https://etherscan.io/address/0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1) |
| L2OutputOracle               | [0xdfe97868233d1aa22e815a266982f2cf17685a27](https://etherscan.io/address/0xdfe97868233d1aa22e815a266982f2cf17685a27) |
| OptimismPortal               | [0xbEb5Fc579115071764c7423A4f12eDde41f106Ed](https://etherscan.io/address/0xbEb5Fc579115071764c7423A4f12eDde41f106Ed) |
| SystemConfig                 | [0x229047fed2591dbec1eF1118d64F7aF3dB9EB290](https://etherscan.io/address/0x229047fed2591dbec1eF1118d64F7aF3dB9EB290) |
| OptimismMintableERC20Factory | [0x75505a97BD334E7BD3C476893285569C4136Fa0F](https://etherscan.io/address/0x75505a97BD334E7BD3C476893285569C4136Fa0F) |


The following table includes the new implementation addresses and the implementation version.

| Contract (Implementation)    | Version | Address                                                                                                               | 
|------------------------------|---------|-----------------------------------------------------------------------------------------------------------------------|
| L1CrossDomainMessenger       | 1.7.0   | [0xDa2332D0a7608919Cd331B1304Cd179129a90495](https://etherscan.io/address/0xDa2332D0a7608919Cd331B1304Cd179129a90495) |
| L1ERC721Bridge               | 1.4.0   | [0x806C2d0d2BDDFf9279CB2A8722F9117f0b0aDE73](https://etherscan.io/address/0x806C2d0d2BDDFf9279CB2A8722F9117f0b0aDE73) |
| L1StandardBridge             | 1.4.0   | [0xcfBCbA6d9E84A3c4FaE0eda9684cE39a09aa2c8A](https://etherscan.io/address/0xcfBCbA6d9E84A3c4FaE0eda9684cE39a09aa2c8A) |
| L2OutputOracle               | 1.6.0   | [0xB48B1827BC7218b1aB7B000b4f0416DF8F14B16A](https://etherscan.io/address/0xB48B1827BC7218b1aB7B000b4f0416DF8F14B16A) |
| OptimismPortal               | 1.10.0  | [0xD14AA6C7B6D92803F3910Ec1DADCCd0757341862](https://etherscan.io/address/0xD14AA6C7B6D92803F3910Ec1DADCCd0757341862) |
| SystemConfig                 | 1.10.0  | [0x3b6090d4ba84B94C20a789436B9010F340AaaC70](https://etherscan.io/address/0x3b6090d4ba84B94C20a789436B9010F340AaaC70) |
| OptimismMintableERC20Factory | 1.6.0   | [0x373B66bd178cb2716D5A9596B1a42Ed39b87A535](https://etherscan.io/address/0x373B66bd178cb2716D5A9596B1a42Ed39b87A535) |

### State Diff

#### SystemConfig

##### `0x0000000000000000000000000000000000000000000000000000000000000000`

| Before                                                               | After                                                                |
|----------------------------------------------------------------------|----------------------------------------------------------------------|
| `0x0000000000000000000000000000000000000000000000000000000000000001` | `0x0000000000000000000000000000000000000000000000000000000000000003` |

| Before | `0x0000000000000000000000000000000000000000000000000000000000000001` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000000000000000000000000000000000000000000000003` |

The `initialized` storage slot was updated from 1 to 3
