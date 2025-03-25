# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council
>
> - Domain Hash: ``
> - Message Hash: ``
>
> ### Optimism Foundation
>
> - Domain Hash: ``
> - Message Hash: ``


## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. OP Mainnet:
    - SystemConfigProxy: [0x229047fed2591dbec1eF1118d64F7aF3dB9EB290](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/op.toml#L58)
    - ProxyAdmin: [0x543bA4AADBAb8f9025686Bd03993043599c6fB04](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/op.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)

2. Soneium:
    - SystemConfigProxy: [0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/soneium.toml#L58)
    - ProxyAdmin: [0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/soneium.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)

3. Ink:
    - SystemConfigProxy: [0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/ink.toml#L58)
    - ProxyAdmin: [0xd56045E68956FCe2576E680c95a4750cf8241f79](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/ink.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)


Thus, the command to encode the calldata to the OPCM's [`upgrade()`](https://github.com/ethereum-optimism/optimism/blob/8d0dd96e494b2ba154587877351e87788336a4ec/packages/contracts-bedrock/src/L1/OPContractsManager.sol#L463) function is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290,0x543bA4AADBAb8f9025686Bd03993043599c6fB04,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9),(0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9),(0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,0xd56045E68956FCe2576E680c95a4750cf8241f79,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

- `target`: [0x026b2f158255beac46c1e7c6b8bbf29a4b6a7b76](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-mainnet.toml#L21) - Mainnet OPContractsManager v2.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x026b2f158255beac46c1e7c6b8bbf29a4b6a7b76,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb04039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d90000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f79039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000026b2f158255beac46c1e7c6b8bbf29a4b6a7b76000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000164ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb04039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d90000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f79039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in the [Action Plan](https://gov.optimism.io/t/upgrade-proposal-13-opcm-and-incident-response-improvements/9739#p-43725-action-plan-15) section of the Governance proposal.

## Tenderly State Changes
[Link](https://dashboard.tenderly.co/oplabs/eth-mainnet/simulator/ab8d86e3-d143-4e0b-9686-3dcab85a8609)

## Auto Generated Task State Changes

```bash
----------------- Task State Changes -------------------

----- DecodedStateDiff[0] -----
  Who:               0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000016
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  [WARN] Slot was not decoded

----- DecodedStateDiff[1] -----
  Who:               0x10d7B35078d3baabB96Dd45a9143B94be65b12CD
  Contract:          DisputeGameFactory
  Chain ID:          57073
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000c641a33cab81c559f2bd4b21ea34c290e2440c2b
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: 0xc641A33cab81C559F2bd4b21EA34C290E2440C2B
  Decoded New Value: 0x4bbA758F006Ef09402eF31724203F316ab74e4a0
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[2] -----
  Who:               0x10d7B35078d3baabB96Dd45a9143B94be65b12CD
  Contract:          DisputeGameFactory
  Chain ID:          57073
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x0000000000000000000000008d9faaeb46cbcf487baf2182e438ac3d0847f637
  Raw New Value:     0x0000000000000000000000004699d20479dfd20e15cab4fcb6f2a7cc6fe35443
  [WARN] Slot was not decoded

----- DecodedStateDiff[3] -----
  Who:               0x10d7B35078d3baabB96Dd45a9143B94be65b12CD
  Contract:          DisputeGameFactory
  Chain ID:          57073
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x0000000000000000000000007e87b471e96b96955044328242456427a0d49694
  Raw New Value:     0x00000000000000000000000069361c9134d620b704c2a72c58523a4373ece86f
  [WARN] Slot was not decoded

----- DecodedStateDiff[4] -----
  Who:               0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c0001
  [WARN] Slot was not decoded

----- DecodedStateDiff[5] -----
  Who:               0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c0
  [WARN] Slot was not decoded

----- DecodedStateDiff[6] -----
  Who:               0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000088e529a6ccd302c948689cd5156c83d4614fae92
  [WARN] Slot was not decoded

----- DecodedStateDiff[7] -----
  Who:               0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0xd1d632a1c83002b4a45f2ffc9116b8f59546921724b729d52d0787372b18c337
  [WARN] Slot was not decoded

----- DecodedStateDiff[8] -----
  Who:               0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000486a0e
  [WARN] Slot was not decoded

----- DecodedStateDiff[9] -----
  Who:               0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1
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

----- DecodedStateDiff[10] -----
  Who:               0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1
  Contract:
  Chain ID:
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.

----- DecodedStateDiff[11] -----
  Who:               0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c0001
  [WARN] Slot was not decoded

----- DecodedStateDiff[12] -----
  Who:               0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9
  [WARN] Slot was not decoded

----- DecodedStateDiff[13] -----
  Who:               0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000beb5fc579115071764c7423a4f12edde41f106ed
  [WARN] Slot was not decoded

----- DecodedStateDiff[14] -----
  Who:               0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x5c957423b18bed04245927a0ab5652675a51d4cc3c611bc51f438fd2d7c18bae
  [WARN] Slot was not decoded

----- DecodedStateDiff[15] -----
  Who:               0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000007f5432d
  [WARN] Slot was not decoded

----- DecodedStateDiff[16] -----
  Who:               0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b
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

----- DecodedStateDiff[17] -----
  Who:               0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b
  Contract:
  Chain ID:
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb04
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x543bA4AADBAb8f9025686Bd03993043599c6fB04
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.

----- DecodedStateDiff[18] -----
  Who:               0x21429aF66058BC3e4aE4a8f2EC4531AaC433ecbC
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

----- DecodedStateDiff[19] -----
  Who:               0x229047fed2591dbec1eF1118d64F7aF3dB9EB290
  Contract:          SystemConfig
  Chain ID:          10
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ab9d6cb7a427c0765163a7f45bb91cafe5f2d375
  Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Decoded Kind:      address
  Decoded Old Value: 0xAB9d6cB7A427c0765163A7f45BB91cAfe5f2D375
  Decoded New Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[20] -----
  Who:               0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c0001
  [WARN] Slot was not decoded

----- DecodedStateDiff[21] -----
  Who:               0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000010d7b35078d3baabb96dd45a9143b94be65b12cd
  [WARN] Slot was not decoded

----- DecodedStateDiff[22] -----
  Who:               0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000005d66c1782664115999c47c9fa5cd031f495d3e4f
  [WARN] Slot was not decoded

----- DecodedStateDiff[23] -----
  Who:               0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0xf24819ad2addf7cb3dc453c6cc17c9bc90288ba932271da6692ebb5be4cbdc74
  [WARN] Slot was not decoded

----- DecodedStateDiff[24] -----
  Who:               0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000000000000000000000000000000000000008afb2f
  [WARN] Slot was not decoded

----- DecodedStateDiff[25] -----
  Who:               0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d
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

----- DecodedStateDiff[26] -----
  Who:               0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d
  Contract:
  Chain ID:
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f79
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0xd56045E68956FCe2576E680c95a4750cf8241f79
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.

----- DecodedStateDiff[27] -----
  Who:               0x323dFC63c9B83CB83f40325AaB74b245937cbdF0
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

----- DecodedStateDiff[28] -----
  Who:               0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0
  Contract:          DisputeGameFactory
  Chain ID:          1868
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000c641a33cab81c559f2bd4b21ea34c290e2440c2b
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: 0xc641A33cab81C559F2bd4b21EA34C290E2440C2B
  Decoded New Value: 0x4bbA758F006Ef09402eF31724203F316ab74e4a0
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[29] -----
  Who:               0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0
  Contract:          DisputeGameFactory
  Chain ID:          1868
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x00000000000000000000000042d15f045159ce4ade9edc7da5704ef36056c936
  Raw New Value:     0x0000000000000000000000001661af719956198628f7e67087f19f8a79524a1d
  [WARN] Slot was not decoded

----- DecodedStateDiff[30] -----
  Who:               0x5933e323bE8896DfaCd1cD671442F27dAA10a053
  Contract:          L1ERC721Bridge
  Chain ID:          1868
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[31] -----
  Who:               0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
  Contract:          ProxyAdminOwner (GnosisSafe)
  Chain ID:          10
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x000000000000000000000000000000000000000000000000000000000000000b
  Raw New Value:     0x000000000000000000000000000000000000000000000000000000000000000c
  Decoded Kind:      uint256
  Decoded Old Value: 11
  Decoded New Value: 12
  Summary:           nonce
  Detail:

----- DecodedStateDiff[32] -----
  Who:               0x5a7749f83b81B301cAb5f48EB8516B986DAef23D
  Contract:          L1ERC721Bridge
  Chain ID:          10
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[33] -----
  Who:               0x5d66C1782664115999C47c9fA5cd031f495D3e4F
  Contract:          OptimismPortal2
  Chain ID:          57073
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0xe2F826324b2faf99E513D16D266c3F80aE87832B
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[34] -----
  Who:               0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364
  Contract:          SystemConfig
  Chain ID:          57073
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886
  Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Decoded Kind:      address
  Decoded Old Value: 0xF56D96B2535B932656d3c04Ebf51baBff241D886
  Decoded New Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[35] -----
  Who:               0x661235a238B11191211fa95D4Dd9E423d521E0Be
  Contract:          L1ERC721Bridge
  Chain ID:          57073
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[36] -----
  Who:               0x75505a97BD334E7BD3C476893285569C4136Fa0F
  Contract:          OptimismMintableERC20Factory
  Chain ID:          10
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[37] -----
  Who:               0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3
  Contract:          SystemConfig
  Chain ID:          1868
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ab9d6cb7a427c0765163a7f45bb91cafe5f2d375
  Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Decoded Kind:      address
  Decoded Old Value: 0xAB9d6cB7A427c0765163A7f45BB91cAfe5f2D375
  Decoded New Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[38] -----
  Who:               0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935
  Contract:
  Chain ID:
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000042f0bd8313ad456a38061308857b2383fe2c72a0
  Raw New Value:     0x00000000000000000000000037e15e4d6dffa9e5e320ee1ec036922e563cb76c
  Decoded Kind:      address
  Decoded Old Value: 0x42F0bD8313ad456A38061308857b2383fe2c72a0
  Decoded New Value: 0x37E15e4d6DFFa9e5E320Ee1eC036922E563CB76C
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[39] -----
  Who:               0x88e529A6ccd302c948689Cd5156C83D4614FAE92
  Contract:          OptimismPortal2
  Chain ID:          1868
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0xe2F826324b2faf99E513D16D266c3F80aE87832B
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[40] -----
  Who:               0x88FF1e5b602916615391F55854588EFcBB7663f0
  Contract:          L1StandardBridge
  Chain ID:          57073
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[41] -----
  Who:               0x95703e0982140D16f8ebA6d158FccEde42f04a4C
  Contract:          SuperchainConfig
  Chain ID:          130
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000053c165169401764778f780a69701385eb0ff19b7
  Raw New Value:     0x0000000000000000000000004da82a327773965b8d4d85fa3db8249b387458e7
  Decoded Kind:      address
  Decoded Old Value: 0x53c165169401764778F780a69701385eb0FF19B7
  Decoded New Value: 0x4da82a327773965b8d4D85Fa3dB8249b387458E7
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[42] -----
  Who:               0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1
  Contract:          L1StandardBridge
  Chain ID:          10
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[43] -----
  Who:               0x9AEA1FD851b63d57Ba4Fc556B0e0c170126C9EAf
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

----- DecodedStateDiff[44] -----
  Who:               0x9b7C9BbD6d540A8A4dEDd935819fC4408Ba71153
  Contract:          AddressManager
  Chain ID:          57073
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded

----- DecodedStateDiff[45] -----
  Who:               0xA8B389A82e088b164cD03230e900980CcED34d29
  Contract:          OptimismMintableERC20Factory
  Chain ID:          57073
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[46] -----
  Who:               0xB24bFEeCE1B3b7A44559F4Cbc21BeD312b130b70
  Contract:          AddressManager
  Chain ID:          1868
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded

----- DecodedStateDiff[47] -----
  Who:               0xbEb5Fc579115071764c7423A4f12eDde41f106Ed
  Contract:          OptimismPortal2
  Chain ID:          10
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0xe2F826324b2faf99E513D16D266c3F80aE87832B
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[48] -----
  Who:               0xc1047e30EFC9E172cFe7aa0219895B6a43fC415F
  Contract:          OptimismMintableERC20Factory
  Chain ID:          1868
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[49] -----
  Who:               0xc4986627A41cdCf6fa33543D96f00F475bCE42f5
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

----- DecodedStateDiff[50] -----
  Who:               0xdE1FCfB0851916CA5101820A69b13a4E276bd81F
  Contract:          AddressManager
  Chain ID:          10
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded

----- DecodedStateDiff[51] -----
  Who:               0xe5965Ab5962eDc7477C8520243A95517CD252fA9
  Contract:          DisputeGameFactory
  Chain ID:          10
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000c641a33cab81c559f2bd4b21ea34c290e2440c2b
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: 0xc641A33cab81C559F2bd4b21EA34C290E2440C2B
  Decoded New Value: 0x4bbA758F006Ef09402eF31724203F316ab74e4a0
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[52] -----
  Who:               0xe5965Ab5962eDc7477C8520243A95517CD252fA9
  Contract:          DisputeGameFactory
  Chain ID:          10
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x00000000000000000000000091a661891248d8c4916fb4a1508492a5e2cbcb87
  Raw New Value:     0x000000000000000000000000d113ad136a0df1c7ffb7f1606be1c778bcfe2f3b
  [WARN] Slot was not decoded

----- DecodedStateDiff[53] -----
  Who:               0xe5965Ab5962eDc7477C8520243A95517CD252fA9
  Contract:          DisputeGameFactory
  Chain ID:          10
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x00000000000000000000000027b81db41f586016694632193b99e45b1a27b8f8
  Raw New Value:     0x000000000000000000000000ba94955ca3422fc57f9d982a0bad2a9c88e2a9d0
  [WARN] Slot was not decoded

----- DecodedStateDiff[54] -----
  Who:               0xeb9bf100225c214Efc3E7C651ebbaDcF85177607
  Contract:          L1StandardBridge
  Chain ID:          1868
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[55] -----
  Who:               0xf6b1554F483C391414d3830927E3600c105AaE6E
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
```
