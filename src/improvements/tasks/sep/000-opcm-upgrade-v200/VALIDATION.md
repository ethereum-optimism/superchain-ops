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
> - Domain Hash: `0x260bd5f92cfcb40d079b1c6f6a7ff07df436553ba65d01934e15aabe1b88657f`
> - Message Hash: `0xb491d2d776a746ea34af0f99dde9520490bbc3dcf5631afe431ffcd4ca1bab33`


## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0. 

By examining each component of the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

```bash
# Final calldata
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001b25f566336f47bc5e0036d66e142237dcf4640b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000164ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d90000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db0039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000
```

### Decode upgrade calldata

```bash
cast calldata-decode 'upgrade((address,address,bytes32)[])' <0xff2dd5a1...>
[
    (
        0x034edD2A225f7f429A63E0f1D2084B9E0A93b538,
        0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    ), 
    (
        0x4Ca9608Fef202216bc21D543798ec854539bAAd3,
        0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    ),
    (
        0x05C993e60179f28bF649a2Bb5b00b5F4283bD525,
        0xd7dB319a49362b2328cf417a934300cCcB442C8d,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```
1. First tuple (OP Sepolia Testnet):
    - SystemConfigProxy: [0x034edD2A225f7f429A63E0f1D2084B9E0A93b538](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/op.toml#L58)
    - ProxyAdmin: [0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/op.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)

2. Second tuple (Soneium Testnet Minato):
    - SystemConfigProxy: [0x4Ca9608Fef202216bc21D543798ec854539bAAd3](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/soneium-minato.toml#L59)
    - ProxyAdmin: [0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/soneium-minato.toml#L60)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)

3. Third tuple (Ink Sepolia):
    - SystemConfigProxy: [0x05C993e60179f28bF649a2Bb5b00b5F4283bD525](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/ink.toml#L58)
    - ProxyAdmin: [0xd7dB319a49362b2328cf417a934300cCcB442C8d](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/ink.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)


- Command to encode: 
  ```bash
  cast calldata 'upgrade((address,address,bytes32)[])' "[(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538,0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9),(0x4Ca9608Fef202216bc21D543798ec854539bAAd3,0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9),(0x05C993e60179f28bF649a2Bb5b00b5F4283bD525,0xd7dB319a49362b2328cf417a934300cCcB442C8d,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"
  ```


### Decode Multicall3DelegateCall calldata:
```bash
cast calldata-decode 'aggregate3((address,bool,bytes)[])' <0x82ad56cb...>

[
    (
        0x1B25F566336F47BC5E0036D66E142237DcF4640b,
        false, 0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d90000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db0039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```

1. First tuple (Call3 struct for Multicall3DelegateCall)
    - `target`: [0x1B25F566336F47BC5E0036D66E142237DcF4640b](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-sepolia.toml#L21) - Sepolia OPContractsManager v2.0.0
    - `allowFailure`: false
    - `callData`: `0xff2dd5a1...`
        - Command to encode: 
        ```bash
        cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1B25F566336F47BC5E0036D66E142237DcF4640b,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d90000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db0039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"
        ```

# State Changes

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### Tenderly State Changes
[Link](https://dashboard.tenderly.co/oplabs/sepolia/simulator/ba323cb0-771a-4b03-81f9-e99b87345b9e)

### Task State Changes

<pre>
 <code>
  ----- DecodedStateDiff[0] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/superchain/configs/sepolia/op.toml#L59">0x034edD2A225f7f429A63E0f1D2084B9E0A93b538</a>
    Contract:          SystemConfig - OP Sepolia Testnet
    Chain ID:          11155420
    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000033b83e4c305c908b2fc181dda36e230213058d7d
    Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
    Decoded Kind:      address
    Decoded Old Value: 0x33b83E4C305c908B2Fc181dDa36e230213058d7d
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L27">0x760C48C62A85045A6B69f07F4a9f22868659CbCc</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ----- DecodedStateDiff[1] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/superchain/configs/sepolia/ink.toml#L59">0x05C993e60179f28bF649a2Bb5b00b5F4283bD525</a>
    Contract:          SystemConfig` - Ink Sepolia
    Chain ID:          763373`
    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
    Raw Old Value:     0x00000000000000000000000033b83e4c305c908b2fc181dda36e230213058d7d`
    Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc`
    Decoded Kind:      address
    Decoded Old Value: 0x33b83E4C305c908B2Fc181dDa36e230213058d7d`
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L27">0x760C48C62A85045A6B69f07F4a9f22868659CbCc</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ----- DecodedStateDiff[2] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/superchain/configs/sepolia/op.toml#L63">0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1</a>
    Contract:          DisputeGameFactory - OP Sepolia Testnet
    Chain ID:          11155420
    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x000000000000000000000000a51bea7e4d34206c0bcb04a776292f2f19f0beec
    Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
    Decoded Kind:      address
    Decoded Old Value: 0xA51bea7E4d34206c0bCB04a776292F2f19F0BeEc
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L34">0x4bbA758F006Ef09402eF31724203F316ab74e4a0</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ----- DecodedStateDiff[3] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/superchain/configs/sepolia/op.toml#L63">0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1</a>
    Contract:          DisputeGameFactory
    Chain ID:          11155420
    Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
    Raw Old Value:     0x0000000000000000000000001c3eb0ebd6195ab587e1ded358a87bdf9b56fe04
    Raw New Value:     0x000000000000000000000000f7529e269a3244921d31304171ae69c44f9c6e09
    [WARN] Slot was not decoded

    // TODO where can I get a link to this new impl?
    Summary: Update Permissioned GameType implementation. 
    Detail: This is gameImpls[1] -> 0xf7529E269A3244921D31304171ae69c44F9c6e09
    Verify that the old implementation is set in this slot using:
        - cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 1 --rpc-url sepolia
        - cast storage 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e --rpc-url sepolia 
    The Raw Slot can be derived from:
        - cast index uint32 1 101
        
  
  ----- DecodedStateDiff[4] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/superchain/configs/sepolia/op.toml#L63">0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1</a>
    Contract:          DisputeGameFactory
    Chain ID:          11155420
    Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
    Raw Old Value:     0x000000000000000000000000927248cb1255e0f02413a758899db4aecffaa5fe
    Raw New Value:     0x0000000000000000000000007982afa9530a3f6b88dd49cd3974cb3121ffb00d
    [WARN] Slot was not decoded

    // TODO where can I get a link to this new impl?
    Summary: Updated CANNON GameType implementation.
    Detail: This is gameImpls[0] -> 0x7982afa9530a3f6b88dd49cd3974cb3121ffb00d`
    where `0` is the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28">CANNON game type</a>.
    Verify that the old implementation is set in this slot using:
        - cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 0 --rpc-url sepolia
        - cast storage 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b --rpc-url sepolia 
    The Raw Slot can be derived from:
        - cast index uint32 0 101
 </code>
</pre>


```bash
#############################################################
#############################################################
#############################################################
##########EVERYTHING ABOVE THIS LINE IS VALIDATED############
#############################################################
#############################################################
#############################################################

----- DecodedStateDiff[5] -----
  Who:               0x16Fc5058F25648194471939df75CF27A2fdC48BC
  Contract:          OptimismPortal2
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0x35028bAe87D71cbC192d545d38F960BA30B4B233
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[6] -----
  Who:               0x1B25F566336F47BC5E0036D66E142237DcF4640b
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000016
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  [WARN] Slot was not decoded

----- DecodedStateDiff[7] -----
  Who:               0x1Eb2fFc903729a0F03966B917003800b145F56E2
  Contract:          ProxyAdminOwner (GnosisSafe)
  Chain ID:          11155420
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000016
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000017
  Decoded Kind:      uint256
  Decoded Old Value: 22
  Decoded New Value: 23
  Summary:           nonce
  Detail:

----- DecodedStateDiff[8] -----
  Who:               0x237840A6Bfd822039d9cC00e1E7BAE280d4F2D49
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

----- DecodedStateDiff[9] -----
  Who:               0x2bfb22cd534a462028771a1cA9D6240166e450c4
  Contract:          L1ERC721Bridge
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[10] -----
  Who:               0x2f3432d169128c49881Cc190520bE6096a9A8D2c
  Contract:
  Chain ID:
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db0
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.

----- DecodedStateDiff[11] -----
  Who:               0x2f3432d169128c49881Cc190520bE6096a9A8D2c
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
  Who:               0x2f3432d169128c49881Cc190520bE6096a9A8D2c
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000c2be75506d5724086deb7245bd260cc9753911be0001
  [WARN] Slot was not decoded

----- DecodedStateDiff[13] -----
  Who:               0x2f3432d169128c49881Cc190520bE6096a9A8D2c
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000b3ad2c38e6e0640d7ce6aa952ab3a60e81bf7a01
  [WARN] Slot was not decoded

----- DecodedStateDiff[14] -----
  Who:               0x2f3432d169128c49881Cc190520bE6096a9A8D2c
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000065ea1489741a5d72ffdd8e6485b216bbdcc15af3
  [WARN] Slot was not decoded

----- DecodedStateDiff[15] -----
  Who:               0x2f3432d169128c49881Cc190520bE6096a9A8D2c
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x07c9e5c189412fe87404502c8f70f6d0f4dc482b7c933fc37424c91d2f7ca06a
  [WARN] Slot was not decoded

----- DecodedStateDiff[16] -----
  Who:               0x2f3432d169128c49881Cc190520bE6096a9A8D2c
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000000000000000000000000000000000000008b969b
  [WARN] Slot was not decoded

----- DecodedStateDiff[17] -----
  Who:               0x33f60714BbD74d62b66D79213C348614DE51901C
  Contract:          L1StandardBridge
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[18] -----
  Who:               0x3454F9df5E750F1383e58c1CB001401e7A4f3197
  Contract:          AddressManager
  Chain ID:          763373
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded

----- DecodedStateDiff[19] -----
  Who:               0x4Ca9608Fef202216bc21D543798ec854539bAAd3
  Contract:          SystemConfig
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000033b83e4c305c908b2fc181dda36e230213058d7d
  Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Decoded Kind:      address
  Decoded Old Value: 0x33b83E4C305c908B2Fc181dDa36e230213058d7d
  Decoded New Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[20] -----
  Who:               0x5c1d29C6c9C8b0800692acC95D700bcb4966A1d7
  Contract:          OptimismPortal2
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0x35028bAe87D71cbC192d545d38F960BA30B4B233
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[21] -----
  Who:               0x5f5a404A5edabcDD80DB05E8e54A78c9EBF000C2
  Contract:          L1StandardBridge
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[22] -----
  Who:               0x6069BC38c6185f2db0d161f08eC8d1657F6078Df
  Contract:          OptimismMintableERC20Factory
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[23] -----
  Who:               0x65ea1489741A5D72fFdD8e6485B216bBdcC15Af3
  Contract:          OptimismPortal2
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: 0x35028bAe87D71cbC192d545d38F960BA30B4B233
  Decoded New Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[24] -----
  Who:               0x686F782A749D1854f6Fa3F948450f4c65c6674f0
  Contract:          OptimismMintableERC20Factory
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[25] -----
  Who:               0x6e8A77673109783001150DFA770E6c662f473DA9
  Contract:          AddressManager
  Chain ID:          1946
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded

----- DecodedStateDiff[26] -----
  Who:               0x79ADD5713B383DAa0a138d3C4780C7A1804a8090
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

----- DecodedStateDiff[27] -----
  Who:               0x860e626c700AF381133D9f4aF31412A2d1DB3D5d
  Contract:          DisputeGameFactory
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000a51bea7e4d34206c0bcb04a776292f2f19f0beec
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: 0xA51bea7E4d34206c0bCB04a776292F2f19F0BeEc
  Decoded New Value: 0x4bbA758F006Ef09402eF31724203F316ab74e4a0
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[28] -----
  Who:               0x860e626c700AF381133D9f4aF31412A2d1DB3D5d
  Contract:          DisputeGameFactory
  Chain ID:          763373
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x00000000000000000000000039228e51a12662d78de478bfa1930fc7595337d8
  Raw New Value:     0x00000000000000000000000083a28245b5f43a66f6199005cfd7bbff58bfeff9
  [WARN] Slot was not decoded

----- DecodedStateDiff[29] -----
  Who:               0x860e626c700AF381133D9f4aF31412A2d1DB3D5d
  Contract:          DisputeGameFactory
  Chain ID:          763373
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x000000000000000000000000323d727a1a147869cec0c02de1d4195d1b71f2eb
  Raw New Value:     0x000000000000000000000000ab3ec4af07756a15533ea6e5d9388a1ab510039c
  [WARN] Slot was not decoded

----- DecodedStateDiff[30] -----
  Who:               0x868D59fF9710159C2B330Cc0fBDF57144dD7A13b
  Contract:          OptimismMintableERC20Factory
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: 0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846
  Decoded New Value: 0x5493f4677A186f64805fe7317D6993ba4863988F
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[31] -----
  Who:               0x9bFE9c5609311DF1c011c47642253B78a4f33F4B
  Contract:          AddressManager
  Chain ID:          11155420
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  [WARN] Slot was not decoded

----- DecodedStateDiff[32] -----
  Who:               0x9C7750C1c7b39E6b0eFeec06A1F2cf06190f6018
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

----- DecodedStateDiff[33] -----
  Who:               0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01
  Contract:          DisputeGameFactory
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000a51bea7e4d34206c0bcb04a776292f2f19f0beec
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: 0xA51bea7E4d34206c0bCB04a776292F2f19F0BeEc
  Decoded New Value: 0x4bbA758F006Ef09402eF31724203F316ab74e4a0
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[34] -----
  Who:               0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01
  Contract:          DisputeGameFactory
  Chain ID:          1946
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x0000000000000000000000003d570de1039b337be88934a778a8ff0e9fb274d2
  Raw New Value:     0x0000000000000000000000005b107ae5823490e643295c62207285069503c364
  [WARN] Slot was not decoded

----- DecodedStateDiff[35] -----
  Who:               0xC2Be75506d5724086DEB7245bd260Cc9753911Be
  Contract:          SuperchainConfig
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000044674af65d36b9d4ac6ba4717369af794c75d9ba
  Raw New Value:     0x0000000000000000000000004da82a327773965b8d4d85fa3db8249b387458e7
  Decoded Kind:      address
  Decoded Old Value: 0x44674AF65D36b9d4AC6ba4717369AF794c75d9BA
  Decoded New Value: 0x4da82a327773965b8d4D85Fa3dB8249b387458E7
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[36] -----
  Who:               0xc69C1ACcdAb9ae28780A238D987a1ACc8bd0FC56
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

----- DecodedStateDiff[37] -----
  Who:               0xcdFdC692a53B4aE9F81E0aEBd26107Da4a71dB84
  Contract:          DelayedWETH
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000007f69b19532476c6cd03056d6bc3f1b110ab7538
  Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
  Decoded Kind:      address
  Decoded Old Value: 0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538
  Decoded New Value: 0x5e40B9231B86984b5150507046e354dbFbeD3d9e
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[38] -----
  Who:               0xd1C901BBD7796546A7bA2492e0E199911fAE68c7
  Contract:          L1ERC721Bridge
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[39] -----
  Who:               0xd83e03D576d23C9AEab8cC44Fa98d058D2176D1f
  Contract:          L1ERC721Bridge
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: 0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d
  Decoded New Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[40] -----
  Who:               0xDa9916204568e2A8d689f775747D9e7FE17F7560
  Contract:
  Chain ID:
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0xd7dB319a49362b2328cf417a934300cCcB442C8d
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.

----- DecodedStateDiff[41] -----
  Who:               0xDa9916204568e2A8d689f775747D9e7FE17F7560
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

----- DecodedStateDiff[42] -----
  Who:               0xDa9916204568e2A8d689f775747D9e7FE17F7560
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000c2be75506d5724086deb7245bd260cc9753911be0001
  [WARN] Slot was not decoded

----- DecodedStateDiff[43] -----
  Who:               0xDa9916204568e2A8d689f775747D9e7FE17F7560
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000860e626c700af381133d9f4af31412a2d1db3d5d
  [WARN] Slot was not decoded

----- DecodedStateDiff[44] -----
  Who:               0xDa9916204568e2A8d689f775747D9e7FE17F7560
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000005c1d29c6c9c8b0800692acc95d700bcb4966a1d7
  [WARN] Slot was not decoded

----- DecodedStateDiff[45] -----
  Who:               0xDa9916204568e2A8d689f775747D9e7FE17F7560
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x742ea618a09335ea1a94c22ac2e643abf463433147dc4a09b7dfacff065342f1
  [WARN] Slot was not decoded

----- DecodedStateDiff[46] -----
  Who:               0xDa9916204568e2A8d689f775747D9e7FE17F7560
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000be8162
  [WARN] Slot was not decoded

----- DecodedStateDiff[47] -----
  Who:               0xDB2727Fc71176Bf8ED630F4142e0439733588e85
  Contract:
  Chain ID:
  Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc
  Summary:           Proxy owner address
  Detail:            Standard slot for storing the owner address in a Proxy contract.

----- DecodedStateDiff[48] -----
  Who:               0xDB2727Fc71176Bf8ED630F4142e0439733588e85
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

----- DecodedStateDiff[49] -----
  Who:               0xDB2727Fc71176Bf8ED630F4142e0439733588e85
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000c2be75506d5724086deb7245bd260cc9753911be0001
  [WARN] Slot was not decoded

----- DecodedStateDiff[50] -----
  Who:               0xDB2727Fc71176Bf8ED630F4142e0439733588e85
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000005f9613adb30026ffd634f38e5c4dfd30a197fa1
  [WARN] Slot was not decoded

----- DecodedStateDiff[51] -----
  Who:               0xDB2727Fc71176Bf8ED630F4142e0439733588e85
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000016fc5058f25648194471939df75cf27a2fdc48bc
  [WARN] Slot was not decoded

----- DecodedStateDiff[52] -----
  Who:               0xDB2727Fc71176Bf8ED630F4142e0439733588e85
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0xcad036c510dd0090bf83ce76cddc4e911c177929a3af6d7bf8fda1f7c5a2e3a7
  [WARN] Slot was not decoded

----- DecodedStateDiff[53] -----
  Who:               0xDB2727Fc71176Bf8ED630F4142e0439733588e85
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x00000000000000000000000000000000000000000000000000000000017b19f1
  [WARN] Slot was not decoded

----- DecodedStateDiff[54] -----
  Who:               0xf6Db90462FEbEB7567fBD064d2ff14a8d0280f3E
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

----- DecodedStateDiff[55] -----
  Who:               0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1
  Contract:          L1StandardBridge
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: 0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF
  Decoded New Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
```