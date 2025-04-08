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
> ### Child Safe 1: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0xbdd593a729dadfa12c86ebac23914145d1ae0418ef1909ffecf78882d6720212`
>
> ### Child Safe 2: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`
>
> - Domain Hash: `0x1d3f2566fd7b1bf017258b03d4d4d435d326d9cb051d5b7993d7c65e7ec78d0e`
> - Message Hash: `0xbdd593a729dadfa12c86ebac23914145d1ae0418ef1909ffecf78882d6720212`


## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Base Sepolia Testnet:
    - SystemConfigProxy: [0xf272670eb55e895584501d564AfEB048bEd26194](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L59)
    - ProxyAdmin: [0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L60)
    - AbsolutePrestate: [0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-prestates.toml#L14)


Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xf272670eb55e895584501d564AfEB048bEd26194,0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3,0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1B25F566336F47BC5E0036D66E142237DcF4640b,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f30354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001b25f566336f47bc5e0036d66e142237dcf4640b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f30354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee0100000000000000000000000000000000000000000000000000000000
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
    Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
    Contract:          AnchorStateRegistryProxy - Base Sepolia Testnet
    Chain ID:          84532

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
    Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
    Contract:          AnchorStateRegistryProxy - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1

    Summary:           Slot 1 is updated to set DisputeGameFactoryProxy address
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L63">0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1</a> is the
                       DisputeGameFactoryProxy address on Base Sepolia Testnet.

  ----- DecodedStateDiff[2] -----
    Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
    Contract:          AnchorStateRegistryProxy - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000002
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x00000000000000000000000049f53e41452c74589e85ca1677426ba426459e85

    Summary:           Slot 2 is updated to set OptimismPortalProxy address
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L58">0x49f53e41452C74589E85cA1677426Ba426459e85</a> is the
                       OptimismPortalProxy address on Base Sepolia Testnet.

  ----- DecodedStateDiff[3] -----
    Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
    Contract:          AnchorStateRegistryProxy - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000004
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0xf85525bc28e0bf794d649c44802171dfd0a390a77a767614c092d468aae11627

    Summary:           Slot 4 updates the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44">'root'</a> for the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L42">startingAnchorRoot</a>
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       The 'Raw New Value' for this entry might be different than what is seen in the Tenderly state diff.
                       This is expected because the AnchorStateRegistry is being continually updated.
                       Anyone can call <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L239"><i>'setAnchorState(IDisputeGame _game)'</i></a> so it can be updated often if the conditions are right.

  ----- DecodedStateDiff[4] -----
    Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
    Contract:
    Chain ID:
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000000000000000000000000000000000000001602fda

    Summary:           Slot 5 updates the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44">'l2BlockNumber'</a> for the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L42">startingAnchorRoot</a>
    Detail:            Please refer to <i>'Figure 0.2'</i> at the end of this report for the storage layout of AnchorStateRegistry.
                       The 'Raw New Value' for this entry might be different than what is seen in the Tenderly state diff.
                       This is expected because the AnchorStateRegistry is being continually updated.
                        - <i>cast --to-dec 0x1602fda</i> -> <i>23080922</i>
                       Anyone can call <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L239"><i>'setAnchorState(IDisputeGame _game)'</i></a> so it can be updated often if the conditions are right.

  ----- DecodedStateDiff[5] -----
    Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
    Contract:          AnchorStateRegistryProxy - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000007b465370bb7a333f99edd19599eb7fb1c2d3f8d2

    Decoded Kind:      address
    Decoded Old Value: 0x0000000000000000000000000000000000000000
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L32">0x7b465370BB7A333f99edd19599EB7Fb1c2D3F8D2</a>

    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       AnchorStateRegistry contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[6] -----
    Who:               0x0729957c92A1F50590A84cb2D65D761093f3f8eB
    Contract:          AnchorStateRegistryProxy - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f3

    Decoded Kind:      address
    Decoded Old Value: 0x0000000000000000000000000000000000000000
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L60">0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3</a>

    Summary:           Proxy owner address
    Detail:            Standard slot for storing the owner address in a Proxy contract.
                       The owner in this case is the <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L60">ProxyAdmin</a> of Base Sepolia Testnet.

  ----- DecodedStateDiff[7] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L45">0x0fe884546476dDd290eC46318785046ef68a0BA9</a>
    Contract:          ProxyAdminOwner (GnosisSafe) - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000013
    Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000014

    Decoded Kind:      uint256
    Decoded Old Value: 19
    Decoded New Value: 20
    Summary:           nonce
    Detail:            The nonce of the ProxyAdminOwner contract is updated.

  ----- TENDERLY ONLY STATE DIFF -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L45">0x0fe884546476dDd290eC46318785046ef68a0BA9</a>
    Contract:          ProxyAdminOwner (GnosisSafe) - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0xb2df5133396593aefbb95e79ed4c7e08db38321b253690a5d0afe88cd55aea1c
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000001

    Summary:           <i>approveHash(bytes32)</i> called on ProxyAdminOwner by child multisig.
    Detail:            As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation.
                       This step isn't shown in the local simulation because the parent
                       multisig is invoked directly, bypassing the <i>approveHash</i> calls.
                       This slot change reflects an update to the approvedHashes mapping.
                       Specifically, this simulation was ran as the nested safe `0x646132A1667ca7aD00d36616AFBA1A28116C770A`.
                        - <i>res=$(cast index address 0x646132A1667ca7aD00d36616AFBA1A28116C770A 8)</i>
                        - <i>cast index bytes32 0x299045e8050d66c48af7217d72265e91cfea17d4af1d4a70469e26d82119d399 $res</i>
                       Alternatively, the 'Raw Slot' value can be different if we run as `0x6AF0674791925f767060Dd52f7fB20984E8639d8`:
                        - <i>res=$(cast index address 0x6AF0674791925f767060Dd52f7fB20984E8639d8 8)</i>
                        - <i>cast index bytes32 0x299045e8050d66c48af7217d72265e91cfea17d4af1d4a70469e26d82119d399 $res</i>
                        - Alternative 'Raw Slot': <i>0x5049591daa2bf73a8b81cc9e1e4d1278ca63f29fe97356d1e7e4bafa181454b1</i>

  ----- DecodedStateDiff[8] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L55">0x21eFD066e581FA55Ef105170Cc04d74386a09190</a>
    Contract:          L1ERC721Bridge - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d
    Raw New Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L58">0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L37">0x276d3730f219f7ec22274f7263180b8452B46d47</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ----- DecodedStateDiff[9] -----
    Who:               0x27A6128F707de3d99F89Bf09c35a4e0753E1B808
    Contract:          DelayedWETH - Base Sepolia Testnet (Permissioned)
    Chain ID:          84532

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000007f69b19532476c6cd03056d6bc3f1b110ab7538
    Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L54">0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L33">0x5e40B9231B86984b5150507046e354dbFbeD3d9e</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       DelayedWETH contract for 'op-contracts/v2.0.0-rc.1'.
                       Using Base Sepolia's <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L63">DisputeGameFactory</a>, we can find this DelayedWETH address:
                        - <i>cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 1 --rpc-url sepolia</i>
                        - <i>cast call 0xCcA6a4916FA6De5D671Cc77760a3b10b012CCa16 "weth()(address)" --rpc-url sepolia</i>
                        returns <b>0x27A6128F707de3d99F89Bf09c35a4e0753E1B808</b>

  ----- DecodedStateDiff[10] -----
    Who:               0x489c2E5ebe0037bDb2DC039C5770757b8E54eA1F
    Contract:          DelayedWETH - Base Sepolia Testnet (Permissionless)
    Chain ID:          84532

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000007f69b19532476c6cd03056d6bc3f1b110ab7538
    Raw New Value:     0x0000000000000000000000005e40b9231b86984b5150507046e354dbfbed3d9e

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L54">0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L33">0x5e40B9231B86984b5150507046e354dbFbeD3d9e</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       DelayedWETH contract for 'op-contracts/v2.0.0-rc.1'.
                       Using Base Sepolia's <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L63">DisputeGameFactory</a>, we can find this DelayedWETH address:
                        - <i>cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 0 --rpc-url sepolia</i>
                        - <i>cast call 0x9cd8B02E84Df3EF61DB3b34123206568490Cb279 "weth()(address)" --rpc-url sepolia</i>
                        returns <b>0x489c2E5ebe0037bDb2DC039C5770757b8E54eA1F</b>

  ----- DecodedStateDiff[11] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L58">0x49f53e41452C74589E85cA1677426Ba426459e85</a>
    Contract:          OptimismPortal2 - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233
    Raw New Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd

    Decoded Kind:      address
    Decoded Old Value: 0x35028bAe87D71cbC192d545d38F960BA30B4B233
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-versions-sepolia.toml#L31">0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ----- TENDERLY ONLY STATE DIFF -----
    Who:               0x6AF0674791925f767060Dd52f7fB20984E8639d8 or 0x646132A1667ca7aD00d36616AFBA1A28116C770A
    Contract:          Child Safe 1 - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000000
    Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000001

    Decoded Kind:      uint256
    Decoded Old Value: 0
    Decoded New Value: 1
    Summary:           nonce
    Detail:            The nonce of the Child Safe 1 contract is updated.
                       Alternatively, the 'Raw Old Value' and 'Raw New Value' value can be different if we run as `0x646132A1667ca7aD00d36616AFBA1A28116C770A`.

  ----- DecodedStateDiff[12] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L53">0x709c2B8ef4A9feFc629A8a2C1AF424Dc5BD6ad1B</a>
    Contract:          AddressManager - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
    Raw Old Value:     0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65
    Raw New Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231

    Summary:           The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v2.0.0-rc.1' L1CrossDomainMessenger at <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L36">0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231</a>.
    Detail:            This key is complicated to compute, so instead we attest to correctness of the key by
                       verifying that the "Before" value currently exists in that slot, as explained below.
                       <b>Before</b> address matches both of the following cast calls:
                        1. What is returned by calling `AddressManager.getAddress()`:
                         - <i>cast call 0x709c2B8ef4A9feFc629A8a2C1AF424Dc5BD6ad1B 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia</i>
                        2. What is currently stored at the key:
                         - <i>cast storage 0x709c2B8ef4A9feFc629A8a2C1AF424Dc5BD6ad1B 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url sepolia</i>

  ----- DecodedStateDiff[13] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L57">0xb1efB9650aD6d0CC1ed3Ac4a0B7f1D5732696D37</a>
    Contract:          OptimismMintableERC20Factory - Base Sepolia Testnet
    Chain ID:          84532

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
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L63">0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1</a>
    Contract:          DisputeGameFactory - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x000000000000000000000000a51bea7e4d34206c0bcb04a776292f2f19f0beec
    Raw New Value:     0x0000000000000000000000004bba758f006ef09402ef31724203f316ab74e4a0

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L55">0xA51bea7E4d34206c0bCB04a776292F2f19F0BeEc</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L34">0x4bbA758F006Ef09402eF31724203F316ab74e4a0</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       DisputeGameFactory contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[15] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L63">0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1</a>
    Contract:          DisputeGameFactory - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
    Raw Old Value:     0x00000000000000000000000058d465e2e31b811fdbbe5461627a0a88c3c1be2f
    Raw New Value:     0x000000000000000000000000d53394d4f67653074acf0b264954fe5e4f72d24f

    Summary:           Update Permissioned GameType implementation.
    Detail:            This is gameImpls[1] -> 0x58d465e2e31b811fdbbe5461627a0a88c3c1be2f
                       Verify that the old implementation is set in this slot using:
                        - <i>cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 1 --rpc-url sepolia</i>
                        - <i>cast storage 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e --rpc-url sepolia</i>
                       The Raw Slot can be derived from:
                        - <i>cast index uint32 1 101</i>

  ----- DecodedStateDiff[16] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L63">0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1</a>
    Contract:          DisputeGameFactory
    Chain ID:          84532
    Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
    Raw Old Value:     0x00000000000000000000000076d7f861bbc8cbef20bad1a3f385eb95dd22306b
    Raw New Value:     0x000000000000000000000000861eb6dfe0fde8c8a63e8606fa487ee870f65e72

    Summary:           Updated CANNON GameType implementation.
    Detail:            This is gameImpls[0] -> 0x861EB6dFE0FDe8c8A63E8606Fa487ee870f65E72 where '0' is the <a href="https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28">CANNON game type</a>.
                       Verify that the old implementation is set in this slot using:
                        - <i>cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 0 --rpc-url sepolia</i>
                        - <i>cast storage 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b --rpc-url sepolia</i>
                       The Raw Slot can be derived from:
                        - <i>cast index uint32 0 101</i>

  ----- DecodedStateDiff[17] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L59">0xf272670eb55e895584501d564AfEB048bEd26194</a>
    Contract:          SystemConfig - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000033b83e4c305c908b2fc181dda36e230213058d7d
    Raw New Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L47">0x33b83E4C305c908B2Fc181dDa36e230213058d7d</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L27">0x760C48C62A85045A6B69f07F4a9f22868659CbCc</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       SystemConfig contract for 'op-contracts/v2.0.0-rc.1'.

  ----- DecodedStateDiff[18] -----
    Who:               <a href="https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L56">0xfd0Bf71F60660E2f608ed56e1659C450eB113120</a>
    Contract:          L1StandardBridge - Base Sepolia Testnet
    Chain ID:          84532

    Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    Raw Old Value:     0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff
    Raw New Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6

    Decoded Kind:      address
    Decoded Old Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L59">0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF</a>
    Decoded New Value: <a href="https://github.com/ethereum-optimism/superchain-registry/blob/84bce73573f130008d84bae6e924163bab589a11/validation/standard/standard-versions-sepolia.toml#L38">0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6</a>
    Summary:           ERC-1967 implementation slot
    Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                       L1StandardBridge contract for 'op-contracts/v2.0.0-rc.1'.

  ----- TENDERLY ONLY STATE DIFF -----

  Three accounts will show a nonce increment:
  - 0x861EB6dFE0FDe8c8A63E8606Fa487ee870f65E72 (the newly created Cannon dispute game)
  - 0xd53394d4f67653074aCf0B264954fe5E4F72D24f (the newly created Permissioned dispute game)
  - 0x7f10098BD53519c739cA8A404afE127647D94774 (the signer of the transaction, alternatively your own address may appear here)

# Supplementary Material

## Figure 0.1: Storage Layout of OPContractsManager

![OPContractsManager isRC flag set to false](../000-opcm-upgrade-v200/images/op-contracts-manager-storage-layout.png)

## Figure 0.2: Storage Layout of AnchorStateRegistryProxy

![AnchorStateRegistryProxy](../000-opcm-upgrade-v200/images/anchor-state-registry-storage-layout.png)
