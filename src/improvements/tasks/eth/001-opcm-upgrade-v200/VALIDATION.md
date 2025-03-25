## Understanding Task Calldata

Multicall3DelegateCall calldata:
```bash
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000026b2f158255beac46c1e7c6b8bbf29a4b6a7b760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000
```

### Decode Multicall3DelegateCall calldata:
```bash
cast calldata-decode 'aggregate3((address,bool,bytes)[])' <0x82ad56cb...>

[
    (
        0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,
        false, 
        0xff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```

1. First tuple (Call3 struct for Multicall3DelegateCall)
    - `target`: [0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-mainnet.toml#L21) - Mainnet OPContractsManager v2.0.0
    - `allowFailure`: false
    - `callData`: `0xff2dd5a1...` See below for decoding.
        - Command to encode: `cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,false,0xff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

### Decode upgrade calldata

```bash
cast calldata-decode 'upgrade((address,address,bytes32)[])' <0xff2dd5a1...>

[
    (
        0x73a79Fab69143498Ed3712e519A88a918e1f4072,
        0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```
1. First tuple (Base):
    - SystemConfigProxy: [0x73a79Fab69143498Ed3712e519A88a918e1f4072](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/base.toml#L59)
    - ProxyAdmin: [0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/base.toml#L60)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)
    - Command to encode: `cast calldata 'upgrade((address,address,bytes32)[])' "[(0x73a79Fab69143498Ed3712e519A88a918e1f4072,0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E, 0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

## Tenderly State Changes

!!!! THIS NEEDS TO BE UPDATED !!!!
[Link](https://dashboard.tenderly.co/oplabs/eth-mainnet/simulator/92acafed-9d5b-48bf-ab41-55bff4a7ba8c)

## Auto Generated Task State Changes

```bash
----------------- Task State Changes -------------------
  
----- DecodedStateDiff[0] -----
  Who:               0x05cc379EBD9B30BbA19C6fA282AB29218EC61D84
  Contract:          OptimismMintableERC20Factory
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
----- DecodedStateDiff[1] -----
  Who:               0x3154Cf16ccdb4C6d922629664174b904d80F2C35
  Contract:          L1StandardBridge
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
----- DecodedStateDiff[2] -----
  Who:               0x3E8a0B63f57e975c268d610ece93da5f78c01321
  Contract:          
  Chain ID:          
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000071e966ae981d1ce531a7b6d23dc0f27b38409087
  Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
  Decoded Kind:      address
  Decoded Old Value: 0x71e966Ae981d1ce531a7b6d23DC0f27B38409087
  Decoded New Value: 0x5e40B9231B86984b5150507046e354dbFbeD3d9e
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
----- DecodedStateDiff[3] -----
  Who:               0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e
  Contract:          DisputeGameFactory
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000c641a33cab81c559f2bd4b21ea34c290e2440c2b
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: 0xc641A33cab81C559F2bd4b21EA34C290E2440C2B
  Decoded New Value: 0x4bbA758F006Ef09402eF31724203F316ab74e4a0
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
----- DecodedStateDiff[4] -----
  Who:               0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e
  Contract:          DisputeGameFactory
  Chain ID:          8453
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x000000000000000000000000f62c15e2f99d4869a925b8f57076cd85335832a2
  Raw New Value:     0x0000000000000000000000008bd2e80e6d1cf1e5c5f0c69972fe2f02b9c046aa
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[5] -----
  Who:               0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e
  Contract:          DisputeGameFactory
  Chain ID:          8453
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x000000000000000000000000c5f3677c3c56db4031ab005a3c9c98e1b79d438e
  Raw New Value:     0x00000000000000000000000013fbbdefa7d9b147a1777a8a5b0f30379e007ac3
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[6] -----
  Who:               0x49048044D57e1C92A77f79988d21Fa8fAF74E97e
  Contract:          OptimismPortal2
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0xe2F826324b2faf99E513D16D266c3F80aE87832B
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
----- DecodedStateDiff[7] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          
  Chain ID:          
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c0001
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[8] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          
  Chain ID:          
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000043edb88c4b80fdd2adff2412a7bebf9df42cb40e
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[9] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          
  Chain ID:          
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000049048044d57e1c92a77f79988d21fa8faf74e97e
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[10] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          
  Chain ID:          
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0xb3256678a081c5448607a7101deb962c91e3fd986c607c22267c81dbc720b53c
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[11] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          
  Chain ID:          
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000001a9e4e7
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[12] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          
  Chain ID:          
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000007b465370bb7a333f99edd19599eb7fb1c2d3f8d2
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x7b465370BB7A333f99edd19599EB7Fb1c2D3F8D2
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
----- DecodedStateDiff[13] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          
  Chain ID:          
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.
  
----- DecodedStateDiff[14] -----
  Who:               0x608d94945A64503E642E6370Ec598e519a2C1E53
  Contract:          L1ERC721Bridge
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
----- DecodedStateDiff[15] -----
  Who:               0x73a79Fab69143498Ed3712e519A88a918e1f4072
  Contract:          SystemConfig
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ab9d6cb7a427c0765163a7f45bb91cafe5f2d375
  Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Decoded Kind:      address
  Decoded Old Value: 0xAB9d6cB7A427c0765163A7f45BB91cAfe5f2D375
  Decoded New Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
----- DecodedStateDiff[16] -----
  Who:               0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c
  Contract:          ProxyAdminOwner (GnosisSafe)
  Chain ID:          8453
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000006
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000007
  Decoded Kind:      uint256
  Decoded Old Value: 6
  Decoded New Value: 7
  Summary:           nonce
  Detail:            
  
----- DecodedStateDiff[17] -----
  Who:               0x8EfB6B5c4767B09Dc9AA6Af4eAA89F749522BaE2
  Contract:          AddressManager
  Chain ID:          8453
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[18] -----
  Who:               0xa2f2aC6F5aF72e494A227d79Db20473Cf7A1FFE8
  Contract:          DelayedWETH
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000071e966ae981d1ce531a7b6d23dc0f27b38409087
  Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
  Decoded Kind:      address
  Decoded Old Value: 0x71e966Ae981d1ce531a7b6d23DC0f27B38409087
  Decoded New Value: 0x5e40B9231B86984b5150507046e354dbFbeD3d9e
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
```