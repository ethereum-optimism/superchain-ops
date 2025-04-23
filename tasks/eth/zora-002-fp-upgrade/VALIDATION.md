# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction. For each contract listed in the state diff, please verify that no contracts or state
changes shown in the Tenderly diff are missing from this document.

Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no
  unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the
  Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the
  addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage
  layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x2aad820ae16105867ec9cddf51a1fdbfdc771635ff7605e0dbd6639fc419bf44`
>
> ### Optimism Foundation
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x44a80fb9661c9682ee398183198b43fc05a04b8bc6eedd3787e8f82876c20a2b`

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md) for the expected
state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the
simulation is:

- Council simulation: `0x1e3b5ffe41447b9cf345c8c598ab59ec07ce0cbc77f39a7162ff9ee9610bb0fa`
- Foundation simulation: `0x86889c852b8337dd38b6b954b0ca42716b95ca392672388371331cd35d11267c`

Calculated as explained in the nested validation doc:

```sh
cast index address 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 8 # council
# 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
cast index bytes32 0x496364fd87984d3d8d051b8205944ea153d9bede161b06b4653fc85b84a753ff 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
# 0x1e3b5ffe41447b9cf345c8c598ab59ec07ce0cbc77f39a7162ff9ee9610bb0fa
```

```sh
cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8 # foundation
# 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
cast index bytes32 0x496364fd87984d3d8d051b8205944ea153d9bede161b06b4653fc85b84a753ff 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
# 0x86889c852b8337dd38b6b954b0ca42716b95ca392672388371331cd35d11267c
```

## State Changes

### `0xA3cAB0126d5F504B071b81a3e8A2BBBF17930d86` (`SystemConfigProxy` on zora mainnet)

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x000000000000000000000000B0F15106fa1e473Ddb39790f197275BC979Aa37e`
- **Meaning**: Slot at keccak(systemconfig.disputegamefactory)-1 set to address of
  DisputeGameFactoryProxy deployed via upgrade script

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
- **Before**: `0x0000000000000000000000009e6204f750cd866b299594e2ac9ea824e2e5f95c`
- **After**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **Meaning**: Slot at keccak(systemconfig.l2outputoracle)-1 deleted

### `0x1a0ad011913A150f69f6A19DF447A0CfD9551054` (`OptimismPortalProxy` on zora mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000038`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x000000000000000000000000b0f15106fa1e473ddb39790f197275bc979aa37e`
- **Meaning**: DisputeGameFactory address variable set to the address deployed in upgrade script

- **Key**: `0x000000000000000000000000000000000000000000000000000000000000003b`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x00000000000000000000000000000000000000000000000TIMESTAMP00000001`
- **Meaning**: Sets the respectedGameType to 1 (permissioned game) and sets the
  respectedGameTypeUpdatedAt timestamp to the time when the upgrade transaction was executed (will
  be a dynamic value)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
- **Before**: `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589`
- **After**: `0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b`
- **Meaning**: Implementation address changed to 0xe2f826324b2faf99e513d16d266c3f80ae87832b
