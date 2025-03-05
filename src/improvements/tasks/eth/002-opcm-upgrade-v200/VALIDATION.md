## Understanding Task Calldata

Multicall3DelegateCall calldata:
```bash
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000026b2f158255beac46c1e7c6b8bbf29a4b6a7b760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000
```

### Decode Multicall3DelegateCall calldata:
```bash
cast calldata-decode 'aggregate3((address,bool,bytes)[])' <0x82ad56cb...>

[
    (
        0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,
        false, 
        0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```

1. First tuple (Call3 struct for Multicall3DelegateCall)
    - `target`: [0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-mainnet.toml#L21) - Mainnet OPContractsManager v2.0.0
    - `allowFailure`: false
    - `callData`: `0xff2dd5a1...` See below for decoding.
        - Command to encode: `cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

### Decode upgrade calldata

```bash
cast calldata-decode 'upgrade((address,address,bytes32)[])' <0xff2dd5a1...>

[
    (
        0xc407398d063f942feBbcC6F80a156b47F3f1BDA6,
        0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```
1. First tuple (Unichain):
    - SystemConfigProxy: [0xc407398d063f942feBbcC6F80a156b47F3f1BDA6](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/unichain.toml#L58)
    - ProxyAdmin: [0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/unichain.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)
    - Command to encode: `cast calldata 'upgrade((address,address,bytes32)[])' "[(0xc407398d063f942feBbcC6F80a156b47F3f1BDA6,0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4, 0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

## Tenderly State Changes
[Link](https://dashboard.tenderly.co/oplabs/eth-mainnet/simulator/42687998-3100-49a8-bf77-7448c707f2b1)

## Auto Generated Task State Changes

```bash
----------------- Task State Changes -------------------

----- DecodedStateDiff[0] -----
  Who:               0x6d5B183F538ABB8572F5cD17109c617b994D5833
  Contract:          ProxyAdminOwner (GnosisSafe)
  Chain ID:          130
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000002
  Decoded Kind:      uint256
  Decoded Old Value: 1
  Decoded New Value: 2
  Summary:           nonce
  Detail:

----- DecodedStateDiff[1] -----
  Who:               0xc407398d063f942feBbcC6F80a156b47F3f1BDA6
  Contract:          SystemConfig
  Chain ID:          130
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886
  Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Decoded Kind:      address
  Decoded Old Value: 0xF56D96B2535B932656d3c04Ebf51baBff241D886
  Decoded New Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[2] -----
  Who:               0x8098F676033A377b9Defe302e9fE6877cD63D575
  Contract:          AddressManager
  Chain ID:          130
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded

----- DecodedStateDiff[3] -----
  Who:               0xD04D0D87E0bd4D2E50286760a3EF323FeA6849Cf
  Contract:          L1ERC721Bridge
  Chain ID:          130
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[4] -----
  Who:               0x81014F44b0a345033bB2b3B21C7a1A308B35fEeA
  Contract:          L1StandardBridge
  Chain ID:          130
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[5] -----
  Who:               0x2F12d621a16e2d3285929C9996f478508951dFe4
  Contract:          DisputeGameFactory
  Chain ID:          130
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000c641a33cab81c559f2bd4b21ea34c290e2440c2b
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: 0xc641A33cab81C559F2bd4b21EA34C290E2440C2B
  Decoded New Value: 0x4bbA758F006Ef09402eF31724203F316ab74e4a0
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[6] -----
  Who:               0x2F12d621a16e2d3285929C9996f478508951dFe4
  Contract:          DisputeGameFactory
  Chain ID:          130
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x000000000000000000000000c457172937ffa9306099ec4f2317903254bf7223
  Raw New Value:     0x0000000000000000000000005fe2becc3dec340d3df04351db8e728cbe4c7450
  [WARN] Slot was not decoded

----- DecodedStateDiff[7] -----
  Who:               0x2F12d621a16e2d3285929C9996f478508951dFe4
  Contract:          DisputeGameFactory
  Chain ID:          130
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x00000000000000000000000008f0f8f4e792d21e16289db7a80759323c446f61
  Raw New Value:     0x000000000000000000000000d2c3c6f4a4c5aa777bd6c476aea58439db0dd844
  [WARN] Slot was not decoded

----- DecodedStateDiff[8] -----
  Who:               0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2
  Contract:          OptimismPortal2
  Chain ID:          130
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0xe2F826324b2faf99E513D16D266c3F80aE87832B
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[9] -----
  Who:               0xA2B597EaeAcb6F627e088cbEaD319e934ED5edad
  Contract:          OptimismMintableERC20Factory
  Chain ID:          130
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[10] -----
  Who:               0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f
  Contract:
  Chain ID:
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.

----- DecodedStateDiff[11] -----
  Who:               0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f
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
  Who:               0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c0001
  [WARN] Slot was not decoded

----- DecodedStateDiff[13] -----
  Who:               0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000002f12d621a16e2d3285929c9996f478508951dfe4
  [WARN] Slot was not decoded

----- DecodedStateDiff[14] -----
  Who:               0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2
  [WARN] Slot was not decoded

----- DecodedStateDiff[15] -----
  Who:               0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x4e040dc2624c8854dd2099a2622c12b914a4b6035da1f67b140e2557307bb2f5
  [WARN] Slot was not decoded

----- DecodedStateDiff[16] -----
  Who:               0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000a1525f
  [WARN] Slot was not decoded

----- DecodedStateDiff[17] -----
  Who:               0x84B268A4101A8c8e3CcB33004F81eD08202bA124
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

----- DecodedStateDiff[18] -----
  Who:               0xc9edb4E340f4E9683B4557bD9db8f9d932177C86
  Contract:          DelayedWETH
  Chain ID:          130
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000071e966ae981d1ce531a7b6d23dc0f27b38409087
  Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
  Decoded Kind:      address
  Decoded Old Value: 0x71e966Ae981d1ce531a7b6d23DC0f27B38409087
  Decoded New Value: 0x5e40B9231B86984b5150507046e354dbFbeD3d9e
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
```