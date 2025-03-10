## Understanding Task Calldata

Multicall3DelegateCall calldata:
```bash
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001b25f566336f47bc5e0036d66e142237dcf4640b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f3039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000
```

### Decode Multicall3DelegateCall calldata:
```bash
cast calldata-decode 'aggregate3((address,bool,bytes)[])' <0x82ad56cb...>

[
    (
        0x1B25F566336F47BC5E0036D66E142237DcF4640b,
        false, 
        0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f3039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```

1. First tuple (Call3 struct for Multicall3DelegateCall)
    - `target`: [0x1B25F566336F47BC5E0036D66E142237DcF4640b](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-sepolia.toml#L21) - Sepolia OPContractsManager v2.0.0
    - `allowFailure`: false
    - `callData`: `0xff2dd5a1...` See below for decoding.
        - Command to encode: `cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1B25F566336F47BC5E0036D66E142237DcF4640b,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f3039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

### Decode upgrade calldata

```bash
cast calldata-decode 'upgrade((address,address,bytes32)[])' <0xff2dd5a1...>

[
    (
        0xf272670eb55e895584501d564AfEB048bEd26194,
        0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```
1. First tuple (Base Sepolia Testnet):
    - SystemConfigProxy: [0xf272670eb55e895584501d564AfEB048bEd26194](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/base.toml#L58)
    - ProxyAdmin: [0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/base.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)
    - Command to encode: `cast calldata 'upgrade((address,address,bytes32)[])' "[(0xf272670eb55e895584501d564AfEB048bEd26194, 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3, 0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

## Tenderly State Changes
[Link](https://dashboard.tenderly.co/oplabs/sepolia/simulator/6b2420de-81c6-412a-bf55-ff3ccc6a1681)

## Auto Generated Task State Changes

```bash
----------------- Task State Changes -------------------

----- DecodedStateDiff[0] -----
  Who:               0x0fe884546476dDd290eC46318785046ef68a0BA9
  Contract:          ProxyAdminOwner (GnosisSafe)
  Chain ID:          84532
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000010
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000011
  Decoded Kind:      uint256
  Decoded Old Value: 16
  Decoded New Value: 17
  Summary:           nonce
  Detail:

----- DecodedStateDiff[1] -----
  Who:               0xf272670eb55e895584501d564AfEB048bEd26194
  Contract:          SystemConfig
  Chain ID:          84532
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000033b83e4c305c908b2fc181dda36e230213058d7d
  Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Decoded Kind:      address
  Decoded Old Value: 0x33b83E4C305c908B2Fc181dDa36e230213058d7d
  Decoded New Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[2] -----
  Who:               0x709c2B8ef4A9feFc629A8a2C1AF424Dc5BD6ad1B
  Contract:          AddressManager
  Chain ID:          84532
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded

----- DecodedStateDiff[3] -----
  Who:               0x21eFD066e581FA55Ef105170Cc04d74386a09190
  Contract:          L1ERC721Bridge
  Chain ID:          84532
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[4] -----
  Who:               0xfd0Bf71F60660E2f608ed56e1659C450eB113120
  Contract:          L1StandardBridge
  Chain ID:          84532
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[5] -----
  Who:               0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1
  Contract:          DisputeGameFactory
  Chain ID:          84532
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000a51bea7e4d34206c0bcb04a776292f2f19f0beec
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: 0xA51bea7E4d34206c0bCB04a776292F2f19F0BeEc
  Decoded New Value: 0x4bbA758F006Ef09402eF31724203F316ab74e4a0
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[6] -----
  Who:               0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1
  Contract:          DisputeGameFactory
  Chain ID:          84532
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x00000000000000000000000071ff927ee7b96f873c249093846aa292f374aef4
  Raw New Value:     0x000000000000000000000000f1c3c054380f6e8345099650a9cc532bb4809868
  [WARN] Slot was not decoded

----- DecodedStateDiff[7] -----
  Who:               0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1
  Contract:          DisputeGameFactory
  Chain ID:          84532
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x000000000000000000000000605b4248500c0a144e39bbb04c05c539e388e222
  Raw New Value:     0x0000000000000000000000005c6a0da1775ba8193f84a1b8c6661b786e36fef6
  [WARN] Slot was not decoded

----- DecodedStateDiff[8] -----
  Who:               0x49f53e41452C74589E85cA1677426Ba426459e85
  Contract:          OptimismPortal2
  Chain ID:          84532
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0x35028bAe87D71cbC192d545d38F960BA30B4B233
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[9] -----
  Who:               0xb1efB9650aD6d0CC1ed3Ac4a0B7f1D5732696D37
  Contract:          OptimismMintableERC20Factory
  Chain ID:          84532
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[10] -----
  Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
  Contract:
  Chain ID:
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f3
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.

----- DecodedStateDiff[11] -----
  Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
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

----- DecodedStateDiff[12] -----
  Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000c2be75506d5724086deb7245bd260cc9753911be0001
  [WARN] Slot was not decoded

----- DecodedStateDiff[13] -----
  Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1
  [WARN] Slot was not decoded

----- DecodedStateDiff[14] -----
  Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000049f53e41452c74589e85ca1677426ba426459e85
  [WARN] Slot was not decoded

----- DecodedStateDiff[15] -----
  Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0xb9e0ba40035ee12806b0490c6d273f68e1bf3940547e06d84b137f9d6cd781a8
  [WARN] Slot was not decoded

----- DecodedStateDiff[16] -----
  Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000000000000000000000000000000000000015b874d
  [WARN] Slot was not decoded

----- DecodedStateDiff[17] -----
  Who:               0x27A6128F707de3d99F89Bf09c35a4e0753E1B808
  Contract:
  Chain ID:
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000007f69b19532476c6cd03056d6bc3f1b110ab7538
  Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
  Decoded Kind:      address
  Decoded Old Value: 0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538
  Decoded New Value: 0x5e40B9231B86984b5150507046e354dbFbeD3d9e
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[18] -----
  Who:               0x489c2E5ebe0037bDb2DC039C5770757b8E54eA1F
  Contract:
  Chain ID:
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000007f69b19532476c6cd03056d6bc3f1b110ab7538
  Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
  Decoded Kind:      address
  Decoded Old Value: 0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538
  Decoded New Value: 0x5e40B9231B86984b5150507046e354dbFbeD3d9e
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
```