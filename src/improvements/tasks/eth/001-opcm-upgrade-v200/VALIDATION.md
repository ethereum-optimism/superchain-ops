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
> ### Child Safe 1: `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`
>
> - Domain Hash: `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0x73a11487da1a8b8e840d4540403a34cedecf821ba4a0291efdf2cff6b081bf39`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Base Mainnet:
    - SystemConfigProxy: [0x73a79Fab69143498Ed3712e519A88a918e1f4072](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/base.toml#L59)
    - ProxyAdmin: [0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/base.toml#L60)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-prestates.toml#L22)


Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x73a79Fab69143498Ed3712e519A88a918e1f4072, 0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E, 0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L60) - Mainnet OPContractsManager v2.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,false,0xff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000026b2f158255beac46c1e7c6b8bbf29a4b6a7b760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-13-opcm-and-incident-response-improvements/9739#p-43725-action-plan-15) section of the Governance proposal.

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### Task State Changes

<pre>
<code>
----- DecodedStateDiff[0] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/base.toml#L57">0x05cc379EBD9B30BbA19C6fA282AB29218EC61D84 </a>
  Contract:          OptimismMintableERC20Factory - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
  Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f
  Decoded Kind:      address
  Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/validation/standard/standard-versions-mainnet.toml#L81">0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846</a>
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L59">0x5493f4677A186f64805fe7317D6993ba4863988F</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                     OptimismMintableERC20Factory contract for 'op-contracts/v2.0.0-rc.1'.

----- DecodedStateDiff[1] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/base.toml#L55">0x3154Cf16ccdb4C6d922629664174b904d80F2C35<a>
  Contract:          L1StandardBridge - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
  Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Decoded Kind:      address
  Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/validation/standard/standard-versions-mainnet.toml#L81">0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF</a>
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/validation/standard/standard-versions-mainnet.toml#L54">0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                     L1StandardBridge contract for 'op-contracts/v2.0.0-rc.1'.

----- DecodedStateDiff[2] -----
  Who:               0x3E8a0B63f57e975c268d610ece93da5f78c01321
  Contract:          DelayedWETH - Base Mainnet (Permissioned)
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000071e966ae981d1ce531a7b6d23dc0f27b38409087
  Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
  Decoded Kind:      address
  Decoded Old Value: 0x71e966Ae981d1ce531a7b6d23DC0f27B38409087
  Decoded New Value: 0x5e40B9231B86984b5150507046e354dbFbeD3d9e
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                     Using Base Mainnet's <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/base.toml#L63">DisputeGameFactory</a>, we can find this DelayedWETH address:
                      - <i>cast call 0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e "gameImpls(uint32)(address)" 1 --rpc-url mainnet</i>
                      - <i>cast call 0xF62c15e2F99d4869A925B8F57076cD85335832A2 "weth()(address)" --rpc-url mainnet</i>
                        returns <b>0x3E8a0B63f57e975c268d610ece93da5f78c01321</b>

----- DecodedStateDiff[3] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/superchain/configs/mainnet/base.toml#L63">0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e</a>
  Contract:          DisputeGameFactory - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000c641a33cab81c559f2bd4b21ea34c290e2440c2b
  Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
  Decoded Kind:      address
  Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/validation/standard/standard-versions-mainnet.toml#L76">0xc641A33cab81C559F2bd4b21EA34C290E2440C2B</a>
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/validation/standard/standard-versions-mainnet.toml#L76">0x4bbA758F006Ef09402eF31724203F316ab74e4a0</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                     DisputeGameFactory contract for 'op-contracts/v2.0.0-rc.1'.

----- DecodedStateDiff[4] -----
  Who:               0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e
  Contract:          DisputeGameFactory - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x000000000000000000000000f62c15e2f99d4869a925b8f57076cd85335832a2
  Raw New Value:     0x0000000000000000000000008bd2e80e6d1cf1e5c5f0c69972fe2f02b9c046aa
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[5] -----
  Who:               0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e
  Contract:          DisputeGameFactory - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x000000000000000000000000c5f3677c3c56db4031ab005a3c9c98e1b79d438e
  Raw New Value:     0x00000000000000000000000013fbbdefa7d9b147a1777a8a5b0f30379e007ac3
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[6] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/superchain/configs/mainnet/base.toml#L58">0x49048044D57e1C92A77f79988d21Fa8fAF74E97e</a>
  Contract:          OptimismPortal2 - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b
  Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Decoded Kind:      address
  Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L72">0xe2F826324b2faf99E513D16D266c3F80aE87832B</a>
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L51">0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                     OptimismPortal contract for 'op-contracts/v2.0.0-rc.1'.

  
----- DecodedStateDiff[7] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          AnchorStateRegistryProxy - Base Mainnet
  Chain ID:          8453
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
  Raw New Value:     0x2e31526db0e371ebf6da52e1f3662801d3352fe8049a573040018c08d94b49cf
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[11] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          
  Chain ID:          
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000001aa8857
  [WARN] Slot was not decoded
  
----- DecodedStateDiff[12] -----
  Who:               0x496286e5eE7758de84Dd17e6d2d97afC2ACE4cc7
  Contract:          AnchorStateRegistryProxy - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  Raw New Value:     0x0000000000000000000000007b465370bb7a333f99edd19599eb7fb1c2d3f8d2
  Decoded Kind:      address
  Decoded Old Value: 0x0000000000000000000000000000000000000000
  Decoded New Value: 0x7b465370BB7A333f99edd19599EB7Fb1c2D3F8D2
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                     AnchorStateRegistry contract for 'op-contracts/v2.0.0-rc.1'.
                     
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
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/superchain/configs/mainnet/base.toml#L54">0x608d94945A64503E642E6370Ec598e519a2C1E53</a>
  Contract:          L1ERC721Bridge - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
  Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Decoded Kind:      address
  Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L78">0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d</a>
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L57">0x276d3730f219f7ec22274f7263180b8452B46d47</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                     L1ERC721Bridge contract for 'op-contracts/v2.0.0-rc.1'

----- DecodedStateDiff[15] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/superchain/configs/mainnet/base.toml#L59">0x73a79Fab69143498Ed3712e519A88a918e1f4072</a>
  Contract:          SystemConfig - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000ab9d6cb7a427c0765163a7f45bb91cafe5f2d375
  Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Decoded Kind:      address
  Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L67">0xAB9d6cB7A427c0765163A7f45BB91cAfe5f2D375</a>
  Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L47">0x760C48C62A85045A6B69f07F4a9f22868659CbCc</a>
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                     SystemConfig contract for 'op-contracts/v2.0.0-rc.1'.

----- DecodedStateDiff[16] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/superchain/configs/mainnet/base.toml#L44">0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c</a>
  Contract:          ProxyAdminOwner (GnosisSafe)
  Chain ID:          8453
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000006
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000007
  Decoded Kind:      uint256
  Decoded Old Value: 6
  Decoded New Value: 7
  Summary:           nonce
  Detail:            The nonce of the ProxyAdminOwner contract is updated.
  
----- DecodedStateDiff[17] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/superchain/configs/mainnet/base.toml#L52">0x8EfB6B5c4767B09Dc9AA6Af4eAA89F749522BaE2</a>
  Contract:          AddressManager - Base Mainnet
  Chain ID:          8453
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
  Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  Summary:           The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v2.0.0-rc.1' L1CrossDomainMessenger at <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-mainnet.toml#L56">0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231</a>.
  Detail:            This key is complicated to compute, so instead we attest to correctness of the key by
                     verifying that the "Before" value currently exists in that slot, as explained below.
                     <b>Before</b> address matches both of the following cast calls:
                      1. What is returned by calling `AddressManager.getAddress()`:
                       - <i>cast call 0x8EfB6B5c4767B09Dc9AA6Af4eAA89F749522BaE2 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url mainnet</i>
                      2. What is currently stored at the key:
                       - <i>cast storage 0x8EfB6B5c4767B09Dc9AA6Af4eAA89F749522BaE2 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url mainnet</i>
  
----- DecodedStateDiff[18] -----
  Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1c314dc0698690aa30ad58ea8f3ee6e63fea858f/superchain/configs/mainnet/base.toml#L62">0xa2f2aC6F5aF72e494A227d79Db20473Cf7A1FFE8</a>
  Contract:          DelayedWETH - Base Mainnet (Permissionless)
  Chain ID:          8453
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000071e966ae981d1ce531a7b6d23dc0f27b38409087
  Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
  Decoded Kind:      address
  Decoded Old Value: 0x71e966Ae981d1ce531a7b6d23DC0f27B38409087
  Decoded New Value: 0x5e40B9231B86984b5150507046e354dbFbeD3d9e
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                    Using Base Mainnet's <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/superchain/configs/mainnet/base.toml#L63">DisputeGameFactory</a>, we can find this DelayedWETH address:
                      - <i>cast call 0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e "gameImpls(uint32)(address)" 1 --rpc-url mainnet</i>
                      - <i>cast call 0xc5f3677c3C56DB4031ab005a3C9c98e1B79D438e "weth()(address)" --rpc-url mainnet</i>
                        returns <b>0xa2f2aC6F5aF72e494A227d79Db20473Cf7A1FFE8</b>
</pre>

# Supplementary Material

## Figure 0.1: Storage Layout of OPContractsManager

![OPContractsManager isRC flag set to false]()

## Figure 0.2: Storage Layout of AnchorStateRegistryProxy

![AnchorStateRegistryProxy]()