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

<details>
<summary>Storage Layout</summary>
<code>
{
  "storage": [
    {
      "astId": 29536,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "_initialized",
      "offset": 0,
      "slot": "0",
      "type": "t_uint8"
    },
    {
      "astId": 29539,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "_initializing",
      "offset": 1,
      "slot": "0",
      "type": "t_bool"
    },
    {
      "astId": 31067,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "__gap",
      "offset": 0,
      "slot": "1",
      "type": "t_array(t_uint256)50_storage"
    },
    {
      "astId": 29408,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "_owner",
      "offset": 0,
      "slot": "51",
      "type": "t_address"
    },
    {
      "astId": 29528,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "__gap",
      "offset": 0,
      "slot": "52",
      "type": "t_array(t_uint256)49_storage"
    },
    {
      "astId": 61692,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "overhead",
      "offset": 0,
      "slot": "101",
      "type": "t_uint256"
    },
    {
      "astId": 61695,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "scalar",
      "offset": 0,
      "slot": "102",
      "type": "t_uint256"
    },
    {
      "astId": 61698,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "batcherHash",
      "offset": 0,
      "slot": "103",
      "type": "t_bytes32"
    },
    {
      "astId": 61701,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "gasLimit",
      "offset": 0,
      "slot": "104",
      "type": "t_uint64"
    },
    {
      "astId": 61705,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "_resourceConfig",
      "offset": 0,
      "slot": "105",
      "type": "t_struct(ResourceConfig)61230_storage"
    },
    {
      "astId": 61718,
      "contract": "src/L1/SystemConfig.sol:SystemConfig",
      "label": "startBlock",
      "offset": 0,
      "slot": "106",
      "type": "t_uint256"
    }
  ],
  "types": {
    "t_address": {
      "encoding": "inplace",
      "label": "address",
      "numberOfBytes": "20"
    },
    "t_array(t_uint256)49_storage": {
      "encoding": "inplace",
      "label": "uint256[49]",
      "numberOfBytes": "1568",
      "base": "t_uint256"
    },
    "t_array(t_uint256)50_storage": {
      "encoding": "inplace",
      "label": "uint256[50]",
      "numberOfBytes": "1600",
      "base": "t_uint256"
    },
    "t_bool": {
      "encoding": "inplace",
      "label": "bool",
      "numberOfBytes": "1"
    },
    "t_bytes32": {
      "encoding": "inplace",
      "label": "bytes32",
      "numberOfBytes": "32"
    },
    "t_struct(ResourceConfig)61230_storage": {
      "encoding": "inplace",
      "label": "struct ResourceMetering.ResourceConfig",
      "numberOfBytes": "32",
      "members": [
        {
          "astId": 61219,
          "contract": "src/L1/SystemConfig.sol:SystemConfig",
          "label": "maxResourceLimit",
          "offset": 0,
          "slot": "0",
          "type": "t_uint32"
        },
        {
          "astId": 61221,
          "contract": "src/L1/SystemConfig.sol:SystemConfig",
          "label": "elasticityMultiplier",
          "offset": 4,
          "slot": "0",
          "type": "t_uint8"
        },
        {
          "astId": 61223,
          "contract": "src/L1/SystemConfig.sol:SystemConfig",
          "label": "baseFeeMaxChangeDenominator",
          "offset": 5,
          "slot": "0",
          "type": "t_uint8"
        },
        {
          "astId": 61225,
          "contract": "src/L1/SystemConfig.sol:SystemConfig",
          "label": "minimumBaseFee",
          "offset": 6,
          "slot": "0",
          "type": "t_uint32"
        },
        {
          "astId": 61227,
          "contract": "src/L1/SystemConfig.sol:SystemConfig",
          "label": "systemTxMaxGas",
          "offset": 10,
          "slot": "0",
          "type": "t_uint32"
        },
        {
          "astId": 61229,
          "contract": "src/L1/SystemConfig.sol:SystemConfig",
          "label": "maximumBaseFee",
          "offset": 14,
          "slot": "0",
          "type": "t_uint128"
        }
      ]
    },
    "t_uint128": {
      "encoding": "inplace",
      "label": "uint128",
      "numberOfBytes": "16"
    },
    "t_uint256": {
      "encoding": "inplace",
      "label": "uint256",
      "numberOfBytes": "32"
    },
    "t_uint32": {
      "encoding": "inplace",
      "label": "uint32",
      "numberOfBytes": "4"
    },
    "t_uint64": {
      "encoding": "inplace",
      "label": "uint64",
      "numberOfBytes": "8"
    },
    "t_uint8": {
      "encoding": "inplace",
      "label": "uint8",
      "numberOfBytes": "1"
    }
  }
}
</code>
</details>

##### `0x0000000000000000000000000000000000000000000000000000000000000000`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000001` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000000000000000000000000000000000000000000000003` |

The `initialized` storage slot was updated from 1 to 3

##### `0x000000000000000000000000000000000000000000000000000000000000006a`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000000000000000000000000000000000000000001177f75` |


This seems like the start block



##### `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

| Before | `0x0000000000000000000000005efa852e92800d1c982711761e45c3fe39a2b6d8` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000000003b6090d4ba84b94c20a789436b9010f340aaac70` |

This is the ERC 1967 proxy implementation slot. It should contain an address and
be set to the old implementation and then updated to the new implementation.

##### `0x383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce9580636`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x00000000000000000000000025ace71c97b33cc4729cf772ae268934f7ab5fa1` |

This is the `L1_CROSS_DOMAIN_MESSENGER_SLOT`. The address of the `L1CrossDomainMessengerProxy`
should be right aligned in the storage slot. It is a net new storage slot so it should
start at `bytes32(0)`.

##### `0x46adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a7`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000000005a7749f83b81b301cab5f48eb8516b986daef23d` |

This is the `L1_ERC_721_BRIDGE_SLOT`. The address of the `L1ERC721BridgeProxy` should be right
aligned in the storage slot. It is a net new storage slot so it should start at `bytes32(0)`.

##### `0x4b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x000000000000000000000000beb5fc579115071764c7423a4f12edde41f106ed` |

This is the `OPTIMISM_PORTAL_SLOT`. The address of the `OptimismPortalProxy` should be right
aligned in the storage slot. It is a net new storage slot so it should start at `bytes32(0)`.

##### `0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x000000000000000000000000ff00000000000000000000000000000000000010` |

This is the `BATCH_INBOX_SLOT`. The canonical address that the batcher sends data to
should be right aligned in the storage slot. It is a net new storage slot so it should
start at `bytes32(0)`.

##### `0x9904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad6376`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x00000000000000000000000099c9fc46f92e8a1c0dec1b1747d010903e884be1` |

This is the `L1_STANDARD_BRIDGE_SLOT`. The address of the `L1StandardBridgeProxy` should be
right aligned in the storage slot. It is a net new storage slot so it should start at
`bytes32(0)`.

##### `0xa04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x00000000000000000000000075505a97bd334e7bd3c476893285569c4136fa0f` |

This is the `OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT`. The address of the `OptimismMintableERC20FactoryProxy`
should be right aligned in the storage slot. It is a net new storage slot so it should start
with `bytes32(0)`.

##### `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x000000000000000000000000dfe97868233d1aa22e815a266982f2cf17685a27` |

This is the `L2_OUTPUT_ORACLE_SLOT`. The address of the `L2OutputOracleProxy` should be
right aligned in the storage slot. It is a net new storage slot so it should start at
`bytes32(0)`.



##### ``

| Before | `` |
|--------|----------------------------------------------------------------------|
| After  | `` |
