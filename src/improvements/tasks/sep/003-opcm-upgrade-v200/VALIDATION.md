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
> ### Single Safe Signer Data
>
> - Domain Hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0x92a19b62607299823103044c19d39f776556d1b8d99ac028145657c4ce8dc8fa`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Unichain Sepolia Testnet:
    - SystemConfigProxy: [0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L59)
    - ProxyAdmin: [0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L60)
    - AbsolutePrestate: [0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-prestates.toml#L14)


Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D, 0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4, 0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0x1B25F566336F47BC5E0036D66E142237DcF4640b](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-sepolia.toml#L21) - Sepolia OPContractsManager v2.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1B25F566336F47BC5E0036D66E142237DcF4640b,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea40354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001b25f566336f47bc5e0036d66e142237dcf4640b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea40354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee0100000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-13-opcm-and-incident-response-improvements/9739#p-43725-action-plan-15) section of the Governance proposal.

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

### Task State Changes

<pre>
  <code>
  ----- DecodedStateDiff[0] -----
    Who:               0x042395c8cC570A20288911dc32E75Beae82aaaa2
    Contract:          AnchorStateRegistryProxy - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000000
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x00000000000000000000c2be75506d5724086deb7245bd260cc9753911be0001
    
    Summary:           Slot 0 is updated to set AnchorStateRegistryProxy address
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       Reading 'Raw New Value' from Right to Left, we have:
                       1. <i>0x01</i> - <i>_initialized</i> flag set to 'true'
                       2. <i>0x00</i> - <i>_initializing</i> flag set to 'false'
                       3. <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/superchain/configs/sepolia/superchain.toml#L3"><i>0xc2be75506d5724086deb7245bd260cc9753911be</i><a> - Sepolia SuperchainConfig

  ----- DecodedStateDiff[1] -----
    Who:               0x042395c8cC570A20288911dc32E75Beae82aaaa2
    Contract:          AnchorStateRegistryProxy - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x000000000000000000000000eff73e5aa3b9aec32c659aa3e00444d20a84394b
    
    Summary:           Slot 1 is updated to set DisputeGameFactoryProxy address
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/superchain/configs/sepolia/unichain.toml#L63">0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b</a> is the
                       DisputeGameFactoryProxy address on Unichain Sepolia Testnet.

  ----- DecodedStateDiff[2] -----
    Who:               0x042395c8cC570A20288911dc32E75Beae82aaaa2
    Contract:          AnchorStateRegistryProxy - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000000d83dab629f0e0f9d36c0cbc89b69a489f0751bd
    
    Summary:           Slot 2 is updated to set OptimismPortalProxy address
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/superchain/configs/sepolia/unichain.toml#L58">0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD</a> is the
                       OptimismPortalProxy address on Unichain Sepolia Testnet.

  ----- DecodedStateDiff[3] -----
    Who:               0x042395c8cC570A20288911dc32E75Beae82aaaa2
    Contract:          AnchorStateRegistryProxy - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x7c52e13adfb1e531ab37ae4c03a42f869fd747c416ebfd7f70cf1afd695260b1
    
    Summary:           Slot 4 updates the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44">'root'</a> for the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L42">startingAnchorRoot</a>
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       The 'Raw New Value' for this entry might be different than what is seen in the Tenderly state diff.
                       This is expected because the AnchorStateRegistry is being continually updated.
                       Anyone can call <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L239"><i>'setAnchorState(IDisputeGame _game)'</i></a> so it can be updated often if the conditions are right.

  ----- DecodedStateDiff[4] -----
    Who:               0x042395c8cC570A20288911dc32E75Beae82aaaa2
    Contract:          AnchorStateRegistryProxy - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000ef5395
    [WARN] Slot was not decoded

    Summary:           Slot 5 updates the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44">'l2BlockNumber'</a> for the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L42">startingAnchorRoot</a>
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       The 'Raw New Value' for this entry might be different than what is seen in the Tenderly state diff.
                       This is expected because the AnchorStateRegistry is being continually updated.
                        - <i>cast --to-dec 0x8baa6f</i> -> <i>15684501</i>
                       Anyone can call <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L239"><i>'setAnchorState(IDisputeGame _game)'</i></a> so it can be updated often if the conditions are right.

  ----- DecodedStateDiff[5] -----
    Who:               0x042395c8cC570A20288911dc32E75Beae82aaaa2
    Contract:          AnchorStateRegistryProxy - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000007b465370bb7a333f99edd19599eb7fb1c2d3f8d2
    
    Decoded Kind:      address
    Decoded Old Value: 0x0000000000000000000000000000000000000000
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-versions-sepolia.toml#L52">0x7b465370BB7A333f99edd19599EB7Fb1c2D3F8D2</a>
    
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       AnchorStateRegistry contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[6] -----
    Who:               0x042395c8cC570A20288911dc32E75Beae82aaaa2
    Contract:          AnchorStateRegistryProxy - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea4
    Decoded Kind:      address
    Decoded Old Value: 0x0000000000000000000000000000000000000000
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L60">0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4</a>
    
    Summary:           Proxy owner address
    Detail:            Standard slot for storing the owner address in a Proxy contract.
                       The owner in this case is the <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L60">ProxyAdmin</a> of Unichain Sepolia Testnet.

  ----- DecodedStateDiff[7] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L58">0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD</a>
    Contract:          OptimismPortal2 - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233
    Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L52">0x35028bAe87D71cbC192d545d38F960BA30B4B233</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L31">0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd</a>

    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       OptimismPortal contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[8] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L55">0x4696b5e042755103fe558738Bcd1ecEe7A45eBfe</a>
    Contract:          L1ERC721Bridge - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
    Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
    
    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L58">0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L37">0x276d3730f219f7ec22274f7263180b8452B46d47</a>
    
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       L1ERC721Bridge contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[9] -----
    Who:               0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae
    Contract:          DelayedWETH - Unichain Sepolia Testnet (Permissionless)
    Chain ID:          1301

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000007f69b19532476c6cd03056d6bc3f1b110ab7538
    Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e
    
    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/c1bcf3601dfdf72f0fd4f5bade180b9c0f94d93b/validation/standard/standard-versions-sepolia.toml#L54">0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/c1bcf3601dfdf72f0fd4f5bade180b9c0f94d93b/validation/standard/standard-versions-sepolia.toml#L33">0x5e40B9231B86984b5150507046e354dbFbeD3d9e</a>
    
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       Using Unichain Sepolia Testnet's <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L63">DisputeGameFactory</a>, we can find this DelayedWETH address:
                        - <i>cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 0 --rpc-url sepolia</i>
                        - <i>cast call 0x1Ca07eBBEd295C581c952Be0eB23E636aed9a2d0 "weth()(address)" --rpc-url sepolia</i>
                        returns <b>0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae</b>

  ----- DecodedStateDiff[10] -----
    Who:               0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c
    Contract:          DelayedWETH - Unichain Sepolia Testnet (Permissioned)
    Chain ID:          1301
    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000007f69b19532476c6cd03056d6bc3f1b110ab7538
    Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/c1bcf3601dfdf72f0fd4f5bade180b9c0f94d93b/validation/standard/standard-versions-sepolia.toml#L54">0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/c1bcf3601dfdf72f0fd4f5bade180b9c0f94d93b/validation/standard/standard-versions-sepolia.toml#L33">0x5e40B9231B86984b5150507046e354dbFbeD3d9e</a>

    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       Using Unichain Sepolia Testnet's <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L63">DisputeGameFactory</a>, we can find this DelayedWETH address:
                        - <i>cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 1 --rpc-url sepolia</i>
                        - <i>cast call 0x98b3cEA8dc27f83a6b8384F25A8eca52613A7182 "weth()(address)" --rpc-url sepolia</i>
                        returns <b>0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c</b>

  ----- DecodedStateDiff[11] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L59">0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D</a>
    Contract:          SystemConfig - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000033b83e4c305c908b2fc181dda36e230213058d7d
    Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-versions-sepolia.toml#L67">0x33b83E4C305c908B2Fc181dDa36e230213058d7d</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L27">0x760C48C62A85045A6B69f07F4a9f22868659CbCc</a>

    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       SystemConfig contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[12] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L45">0xd363339eE47775888Df411A163c586a8BdEA9dbf</a>
    Contract:          ProxyAdminOwner (GnosisSafe) - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
    Raw Old Value:     0x000000000000000000000000000000000000000000000000000000000000001b
    Raw New Value:     0x000000000000000000000000000000000000000000000000000000000000001c

    Decoded Kind:      uint256
    Decoded Old Value: 27
    Decoded New Value: 28
    
    Summary:           nonce
    Detail:            The nonce of the ProxyAdminOwner contract is updated.

  ----- DecodedStateDiff[13] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L57">0xDf7977C3005730329A160637E8CB9f1675A4d9Be</a>
    Contract:          OptimismMintableERC20Factory - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846
    Raw New Value:     0x0000000000000000000000005493f4677a186f64805fe7317d6993ba4863988f

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L61">0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L39">0x5493f4677A186f64805fe7317D6993ba4863988F</a>

    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       OptimismMintableERC20Factory contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[14] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L56">0xea58fcA6849d79EAd1f26608855c2D6407d54Ce2</a>
    Contract:          L1StandardBridge - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
    Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/c1bcf3601dfdf72f0fd4f5bade180b9c0f94d93b/validation/standard/standard-versions-sepolia.toml#L59">0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/c1bcf3601dfdf72f0fd4f5bade180b9c0f94d93b/validation/standard/standard-versions-sepolia.toml#L38">0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       L1StandardBridge contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[15] -----
    Who:               0xEf1295ED471DFEC101691b946fb6B4654E88f98A
    Contract:          AddressManager - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
    Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
    Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
    [WARN] Slot was not decoded

    Summary:           The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v2.0.0-rc.1' L1CrossDomainMessenger at <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L36">0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231</a>.
    Detail:            This key is complicated to compute, so instead we attest to correctness of the key by
                       verifying that the "Before" value currently exists in that slot, as explained below.
                       <b>Before</b> address matches both of the following cast calls:
                        1. What is returned by calling `AddressManager.getAddress()`:
                         - <i>cast call 0xEf1295ED471DFEC101691b946fb6B4654E88f98A 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia</i>
                        2. What is currently stored at the key:
                         - <i>cast storage 0xEf1295ED471DFEC101691b946fb6B4654E88f98A 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url sepolia</i>

  ----- DecodedStateDiff[16] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L63">0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b</a>
    Contract:          DisputeGameFactory - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x000000000000000000000000a51bea7e4d34206c0bcb04a776292f2f19f0beec
    Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0
    
    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L55">0xA51bea7E4d34206c0bCB04a776292F2f19F0BeEc</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L34">0x4bbA758F006Ef09402eF31724203F316ab74e4a0</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       DisputeGameFactory contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[17] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L63">0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b</a>
    Contract:          DisputeGameFactory - Unichain Sepolia Testnet
    Chain ID:          1301

    Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
    Raw Old Value:     0x00000000000000000000000098b3cea8dc27f83a6b8384f25a8eca52613a7182
    Raw New Value:     0x0000000000000000000000002275d0c824116ad516987048fffabac6b0c3a29b

    Summary:           Update Permissioned GameType implementation.
    Detail:            This is gameImpls[1] -> 0x2275d0c824116ad516987048fffabac6b0c3a29b
                       Verify that the old implementation is set in this slot using:
                        - <i>cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 1 --rpc-url sepolia</i>
                        - <i>cast storage 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e --rpc-url sepolia</i>
                       The Raw Slot can be derived from:
                        - <i>cast index uint32 1 101</i>

  ----- DecodedStateDiff[18] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L63">0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b</a>
    Contract:          DisputeGameFactory - Unichain Sepolia Testnet
    Chain ID:          1301
    
    Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
    Raw Old Value:     0x0000000000000000000000001ca07ebbed295c581c952be0eb23e636aed9a2d0
    Raw New Value:     0x0000000000000000000000004745808cc649f290439763214fc40ac905806d8d
    
    Summary:           Updated CANNON GameType implementation.
    Detail:            This is gameImpls[0] -> 0x4745808cc649f290439763214fc40ac905806d8d where '0' is the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28">CANNON game type</a>.
                       Verify that the old implementation is set in this slot using:
                        - <i>cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 0 --rpc-url sepolia</i>
                        - <i>cast storage 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b 0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b --rpc-url sepolia</i>
                       The Raw Slot can be derived from:
                        - <i>cast index uint32 0 101</i>

    ----- Additional Nonce Changes -----
      Who:               0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38, 0x2275D0c824116aD516987048fFfaBAC6B0C3A29B, 0x4745808Cc649f290439763214fC40Ac905806d8D

      Details:           Nonce Updates for all addresses listed above.
      Summary:           All nonces go from 0 to 1.
                          - 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 is address(uint160(uint256(keccak256('foundry default caller'))))
                          - 0x2275D0c824116aD516987048fFfaBAC6B0C3A29B is Permissioned GameType Implementation as per <a href="https://eip.tools/eip/eip-161.md">EIP-161</a>.
                          - 0x4745808Cc649f290439763214fC40Ac905806d8D is Permissionless GameType Implementatio as per <a href="https://eip.tools/eip/eip-161.md">EIP-161</a>.
  </pre>

# Supplementary Material

## Figure 0.1: Storage Layout of OPContractsManager

![OPContractsManager isRC flag set to false](../000-opcm-upgrade-v200/images/op-contracts-manager-storage-layout.png)

## Figure 0.2: Storage Layout of AnchorStateRegistryProxy

![AnchorStateRegistryProxy](../000-opcm-upgrade-v200/images/anchor-state-registry-storage-layout.png)
