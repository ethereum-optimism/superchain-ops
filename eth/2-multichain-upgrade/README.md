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

Terminology:
- `offset`: number of bytes right padded

#### SystemConfigProxy

| Address                                      | Proxy Type |
|----------------------------------------------|------------|
| `0x229047fed2591dbec1ef1118d64f7af3db9eb290` | 1967       |

<details>
<summary>Storage Layout</summary>
<code>{
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
} </code>
</details>

##### `0x0000000000000000000000000000000000000000000000000000000000000000`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000001` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000000000000000000000000000000000000000000000003` |

The `initialized` storage slot was updated from 1 to 3. The `_initializing` storage slot
is set and unset during execution. The `reinitializer` pattern is [used](https://github.com/ethereum-optimism/optimism/blob/f7b8a31de50c54fc252c7ab5e6cf33730a2d9939/packages/contracts-bedrock/src/L1/SystemConfig.sol#L168C33-L168C44)
with a value of `uint8(3)`, see [here](https://github.com/ethereum-optimism/optimism/blob/06c19a4a88f192d07bd2c0369d5b410cb398ef34/packages/contracts-bedrock/src/libraries/Constants.sol#L49).

##### `0x000000000000000000000000000000000000000000000000000000000000006a`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000000000000000000000000000000000000000001177f75` |

Slot 106 (0x6a) is the `startBlock` field. It should be set to the block that the
`SystemConfig` was initialized in. The [following](https://github.com/ethereum-optimism/optimism/commit/a22c0f9bb678323e448de997c9db655a3b93a4ad)
PR set the value in the deploy config. The value set in the deploy config was pulled
from [this](https://etherscan.io/tx/0x76bceccd7d44656f5a129a600a6120091570b897c1d45c18cd7134cfe67c2537)
transaction which indicates that the `SystemConfig` was initialized in block 17422444.

TODO: looks like `startBlock` is 0 in this simulation, going to need to update that.
The state diff does not match the expected.

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

#### L1CrossDomainMessengerProxy

| Address                                      | Proxy Type       |
|----------------------------------------------|------------------|
| `0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1` | ResolvedDelegate |

<details>
<summary>Storage Layout</summary>
<code>{
  "storage": [
    {
      "astId": 75545,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_0_0_20",
      "offset": 0,
      "slot": "0",
      "type": "t_address"
    },
    {
      "astId": 29536,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "_initialized",
      "offset": 20,
      "slot": "0",
      "type": "t_uint8"
    },
    {
      "astId": 29539,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "_initializing",
      "offset": 21,
      "slot": "0",
      "type": "t_bool"
    },
    {
      "astId": 75552,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_1_0_1600",
      "offset": 0,
      "slot": "1",
      "type": "t_array(t_uint256)50_storage"
    },
    {
      "astId": 75555,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_51_0_20",
      "offset": 0,
      "slot": "51",
      "type": "t_address"
    },
    {
      "astId": 75560,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_52_0_1568",
      "offset": 0,
      "slot": "52",
      "type": "t_array(t_uint256)49_storage"
    },
    {
      "astId": 75563,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_101_0_1",
      "offset": 0,
      "slot": "101",
      "type": "t_bool"
    },
    {
      "astId": 75568,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_102_0_1568",
      "offset": 0,
      "slot": "102",
      "type": "t_array(t_uint256)49_storage"
    },
    {
      "astId": 75571,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_151_0_32",
      "offset": 0,
      "slot": "151",
      "type": "t_uint256"
    },
    {
      "astId": 75576,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_152_0_1568",
      "offset": 0,
      "slot": "152",
      "type": "t_array(t_uint256)49_storage"
    },
    {
      "astId": 75581,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_201_0_32",
      "offset": 0,
      "slot": "201",
      "type": "t_mapping(t_bytes32,t_bool)"
    },
    {
      "astId": 75586,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "spacer_202_0_32",
      "offset": 0,
      "slot": "202",
      "type": "t_mapping(t_bytes32,t_bool)"
    },
    {
      "astId": 75634,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "successfulMessages",
      "offset": 0,
      "slot": "203",
      "type": "t_mapping(t_bytes32,t_bool)"
    },
    {
      "astId": 75637,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "xDomainMsgSender",
      "offset": 0,
      "slot": "204",
      "type": "t_address"
    },
    {
      "astId": 75640,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "msgNonce",
      "offset": 0,
      "slot": "205",
      "type": "t_uint240"
    },
    {
      "astId": 75645,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "failedMessages",
      "offset": 0,
      "slot": "206",
      "type": "t_mapping(t_bytes32,t_bool)"
    },
    {
      "astId": 75650,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "__gap",
      "offset": 0,
      "slot": "207",
      "type": "t_array(t_uint256)42_storage"
    },
    {
      "astId": 58880,
      "contract": "src/L1/L1CrossDomainMessenger.sol:L1CrossDomainMessenger",
      "label": "PORTAL",
      "offset": 0,
      "slot": "249",
      "type": "t_contract(OptimismPortal)60944"
    }
  ],
  "types": {
    "t_address": {
      "encoding": "inplace",
      "label": "address",
      "numberOfBytes": "20"
    },
    "t_array(t_uint256)42_storage": {
      "encoding": "inplace",
      "label": "uint256[42]",
      "numberOfBytes": "1344",
      "base": "t_uint256"
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
    "t_contract(OptimismPortal)60944": {
      "encoding": "inplace",
      "label": "contract OptimismPortal",
      "numberOfBytes": "20"
    },
    "t_mapping(t_bytes32,t_bool)": {
      "encoding": "mapping",
      "key": "t_bytes32",
      "label": "mapping(bytes32 => bool)",
      "numberOfBytes": "32",
      "value": "t_bool"
    },
    "t_uint240": {
      "encoding": "inplace",
      "label": "uint240",
      "numberOfBytes": "30"
    },
    "t_uint256": {
      "encoding": "inplace",
      "label": "uint256",
      "numberOfBytes": "32"
    },
    "t_uint8": {
      "encoding": "inplace",
      "label": "uint8",
      "numberOfBytes": "1"
    }
  }
}</code>
</details>

##### `0x0000000000000000000000000000000000000000000000000000000000000000`

| Before | `0x000000000000000000000001de1fcfb0851916ca5101820a69b13a4e276bd81f` |
|--------|----------------------------------------------------------------------|
| After  | `0x000000000000000000000003de1fcfb0851916ca5101820a69b13a4e276bd81f` |

TODO: not sure what this is?

##### `0x00000000000000000000000000000000000000000000000000000000000000f9`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x000000000000000000000000beb5fc579115071764c7423a4f12edde41f106ed` |

Slot 249 (0xf9) is the address of the `OptimismPortalProxy`. This is a new addition
to the contract storage as the value previously was an `immutable`.

#### L1ERC721BridgeProxy

| Address                                      | Proxy Type       |
|----------------------------------------------|------------------|
| `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | 1967             |

The `L1ERC721Bridge` implementation was not part of the storage layout locking tooling
when this change was made. The most important thing is that no existing storage slots
were altered as part of this PR. Commit `57aa6104e16ecd33719b0f58a05b56f7c30cd996`
is right before the change to the storage layout and it shows that the `deposits`
mapping was not moved.

<details>
<summary>Storage Layout</summary>
<code>{
  "storage": [
    {
      "astId": 32100,
      "contract": "src/L1/L1ERC721Bridge.sol:L1ERC721Bridge",
      "label": "_initialized",
      "offset": 0,
      "slot": "0",
      "type": "t_uint8"
    },
    {
      "astId": 32103,
      "contract": "src/L1/L1ERC721Bridge.sol:L1ERC721Bridge",
      "label": "_initializing",
      "offset": 1,
      "slot": "0",
      "type": "t_bool"
    },
    {
      "astId": 76081,
      "contract": "src/L1/L1ERC721Bridge.sol:L1ERC721Bridge",
      "label": "messenger",
      "offset": 2,
      "slot": "0",
      "type": "t_contract(CrossDomainMessenger)76066"
    },
    {
      "astId": 76089,
      "contract": "src/L1/L1ERC721Bridge.sol:L1ERC721Bridge",
      "label": "__gap",
      "offset": 0,
      "slot": "1",
      "type": "t_array(t_uint256)48_storage"
    },
    {
      "astId": 59036,
      "contract": "src/L1/L1ERC721Bridge.sol:L1ERC721Bridge",
      "label": "deposits",
      "offset": 0,
      "slot": "49",
      "type": "t_mapping(t_address,t_mapping(t_address,t_mapping(t_uint256,t_bool)))"
    }
  ],
  "types": {
    "t_address": {
      "encoding": "inplace",
      "label": "address",
      "numberOfBytes": "20"
    },
    "t_array(t_uint256)48_storage": {
      "encoding": "inplace",
      "label": "uint256[48]",
      "numberOfBytes": "1536",
      "base": "t_uint256"
    },
    "t_bool": {
      "encoding": "inplace",
      "label": "bool",
      "numberOfBytes": "1"
    },
    "t_contract(CrossDomainMessenger)76066": {
      "encoding": "inplace",
      "label": "contract CrossDomainMessenger",
      "numberOfBytes": "20"
    },
    "t_mapping(t_address,t_mapping(t_address,t_mapping(t_uint256,t_bool)))": {
      "encoding": "mapping",
      "key": "t_address",
      "label": "mapping(address => mapping(address => mapping(uint256 => bool)))",
      "numberOfBytes": "32",
      "value": "t_mapping(t_address,t_mapping(t_uint256,t_bool))"
    },
    "t_mapping(t_address,t_mapping(t_uint256,t_bool))": {
      "encoding": "mapping",
      "key": "t_address",
      "label": "mapping(address => mapping(uint256 => bool))",
      "numberOfBytes": "32",
      "value": "t_mapping(t_uint256,t_bool)"
    },
    "t_mapping(t_uint256,t_bool)": {
      "encoding": "mapping",
      "key": "t_uint256",
      "label": "mapping(uint256 => bool)",
      "numberOfBytes": "32",
      "value": "t_bool"
    },
    "t_uint256": {
      "encoding": "inplace",
      "label": "uint256",
      "numberOfBytes": "32"
    },
    "t_uint8": {
      "encoding": "inplace",
      "label": "uint8",
      "numberOfBytes": "1"
    }
  }
}</code>
</details>

##### `0x0000000000000000000000000000000000000000000000000000000000000000`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000025ace71c97b33cc4729cf772ae268934f7ab5fa10003` |

Storage slot `bytes32(0)` contains three storage variables. At offset 0, the `_initialized`
variable exists. This should be set to `uint8(3)` like all of the other contracts. The
`_initializing` variable should be empty as it is only transiently set. The address
of the `L1ERC721BridgeProxy` should be at offset 2.

##### `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

| Before | `0x0000000000000000000000003268ed09f76e619331528270b6267d4d2c5ab5c2` |
|--------|----------------------------------------------------------------------|
| After  | `0x000000000000000000000000806c2d0d2bddff9279cb2a8722f9117f0b0ade73` |

This is the ERC 1967 proxy implementation slot. It should contain an address and
be set to the old implementation and then updated to the new implementation.

#### OptimismMintableERC20FactoryProxy

| Address                                      | Proxy Type       |
|----------------------------------------------|------------------|
| `0x5a7749f83b81B301cAb5f48EB8516B986DAef23D` | 1967             |

<details>
<summary>Storage Layout</summary>
<code>{
  "storage": [
    {
      "astId": 32100,
      "contract": "src/universal/OptimismMintableERC20Factory.sol:OptimismMintableERC20Factory",
      "label": "_initialized",
      "offset": 0,
      "slot": "0",
      "type": "t_uint8"
    },
    {
      "astId": 32103,
      "contract": "src/universal/OptimismMintableERC20Factory.sol:OptimismMintableERC20Factory",
      "label": "_initializing",
      "offset": 1,
      "slot": "0",
      "type": "t_bool"
    },
    {
      "astId": 76835,
      "contract": "src/universal/OptimismMintableERC20Factory.sol:OptimismMintableERC20Factory",
      "label": "bridge",
      "offset": 2,
      "slot": "0",
      "type": "t_address"
    }
  ],
  "types": {
    "t_address": {
      "encoding": "inplace",
      "label": "address",
      "numberOfBytes": "20"
    },
    "t_bool": {
      "encoding": "inplace",
      "label": "bool",
      "numberOfBytes": "1"
    },
    "t_uint8": {
      "encoding": "inplace",
      "label": "uint8",
      "numberOfBytes": "1"
    }
  }
}</code>
</details>

##### `0x0000000000000000000000000000000000000000000000000000000000000000`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000099c9fc46f92e8a1c0dec1b1747d010903e884be10003` |

There are 3 different variables packed in the storage slot at `bytes32(0)`.
At offset 0, the `_initialized` variable exists and should be set to `uint8(3)`.
At offset 1, the `_initializing` variable exists and should be set to `uint8(0)`
because it is only transiently used. At offset 2, the `bridge` variable exists
and should be set to the address of the `L1StandardBridgeProxy`.

##### `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

| Before | `0x000000000000000000000000ae849efa4bcfc419593420e14707996936e365e2` |
|--------|----------------------------------------------------------------------|
| After  | `0x000000000000000000000000373b66bd178cb2716d5a9596b1a42ed39b87a535` |

This is the ERC 1967 proxy implementation slot. It should contain an address and
be set to the old implementation and then updated to the new implementation.

#### L1StandardBridgeProxy

| Address                                      | Proxy Type        |
|----------------------------------------------|-------------------|
| `0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1` | L1ChugsplashProxy |

<details>
<summary>Storage Layout</summary>
<code>{
  "storage": [
    {
      "astId": 32100,
      "contract": "src/L1/L1StandardBridge.sol:L1StandardBridge",
      "label": "_initialized",
      "offset": 0,
      "slot": "0",
      "type": "t_uint8"
    },
    {
      "astId": 32103,
      "contract": "src/L1/L1StandardBridge.sol:L1StandardBridge",
      "label": "_initializing",
      "offset": 1,
      "slot": "0",
      "type": "t_bool"
    },
    {
      "astId": 78182,
      "contract": "src/L1/L1StandardBridge.sol:L1StandardBridge",
      "label": "spacer_0_2_20",
      "offset": 2,
      "slot": "0",
      "type": "t_address"
    },
    {
      "astId": 78185,
      "contract": "src/L1/L1StandardBridge.sol:L1StandardBridge",
      "label": "spacer_1_0_20",
      "offset": 0,
      "slot": "1",
      "type": "t_address"
    },
    {
      "astId": 78192,
      "contract": "src/L1/L1StandardBridge.sol:L1StandardBridge",
      "label": "deposits",
      "offset": 0,
      "slot": "2",
      "type": "t_mapping(t_address,t_mapping(t_address,t_uint256))"
    },
    {
      "astId": 78196,
      "contract": "src/L1/L1StandardBridge.sol:L1StandardBridge",
      "label": "messenger",
      "offset": 0,
      "slot": "3",
      "type": "t_contract(CrossDomainMessenger)76066"
    },
    {
      "astId": 78201,
      "contract": "src/L1/L1StandardBridge.sol:L1StandardBridge",
      "label": "__gap",
      "offset": 0,
      "slot": "4",
      "type": "t_array(t_uint256)46_storage"
    }
  ],
  "types": {
    "t_address": {
      "encoding": "inplace",
      "label": "address",
      "numberOfBytes": "20"
    },
    "t_array(t_uint256)46_storage": {
      "encoding": "inplace",
      "label": "uint256[46]",
      "numberOfBytes": "1472",
      "base": "t_uint256"
    },
    "t_bool": {
      "encoding": "inplace",
      "label": "bool",
      "numberOfBytes": "1"
    },
    "t_contract(CrossDomainMessenger)76066": {
      "encoding": "inplace",
      "label": "contract CrossDomainMessenger",
      "numberOfBytes": "20"
    },
    "t_mapping(t_address,t_mapping(t_address,t_uint256))": {
      "encoding": "mapping",
      "key": "t_address",
      "label": "mapping(address => mapping(address => uint256))",
      "numberOfBytes": "32",
      "value": "t_mapping(t_address,t_uint256)"
    },
    "t_mapping(t_address,t_uint256)": {
      "encoding": "mapping",
      "key": "t_address",
      "label": "mapping(address => uint256)",
      "numberOfBytes": "32",
      "value": "t_uint256"
    },
    "t_uint256": {
      "encoding": "inplace",
      "label": "uint256",
      "numberOfBytes": "32"
    },
    "t_uint8": {
      "encoding": "inplace",
      "label": "uint8",
      "numberOfBytes": "1"
    }
  }
}</code>
</details>

##### `0x0000000000000000000000000000000000000000000000000000000000000000`

| Before | `0x00000000000000000000000025ace71c97b33cc4729cf772ae268934f7ab5fa1` |
|--------|----------------------------------------------------------------------|
| After  | `0x0000000000000000000000000000000000000000000000000000000000000003` |

The storage slot at `bytes32(0)` is a legacy spacer. It contains an address on OP
Mainnet but is empty on other networks. Based on how `Initializable` works, it
must be set to `bytes32(0)` transiently before `initialize` is called. To ensure
that the rest of the storage layout is kept, the slot at `bytes32(0)` is repurposed
to holding both `_initializing` and `_initialized`. The `_initialized` value should
by `uint8(3)` and the `_initializing` should be `uint8(0)`.

##### `0x0000000000000000000000000000000000000000000000000000000000000003`

| Before | `0x0000000000000000000000000000000000000000000000000000000000000000` |
|--------|----------------------------------------------------------------------|
| After  | `0x00000000000000000000000025ace71c97b33cc4729cf772ae268934f7ab5fa1` |

This storage slot should be the address of the `L1CrossDomainMessengerProxy`.

##### `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

| Before | `0x000000000000000000000000bfb731cd36d26c2a7287716de857e4380c73a64a` |
|--------|----------------------------------------------------------------------|
| After  | `0x000000000000000000000000cfbcba6d9e84a3c4fae0eda9684ce39a09aa2c8a` |

TODO

-------------
#### 

| Address                                      | Proxy Type       |
|----------------------------------------------|------------------|
| `` | |

##### ``

| Before | `` |
|--------|----------------------------------------------------------------------|
| After  | `` |
