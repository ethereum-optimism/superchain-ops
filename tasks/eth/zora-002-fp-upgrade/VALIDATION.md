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

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md) for the expected
state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the
simulation is:

- Council simulation: `0x6ddce46c849f3c4f07b6936372b065bbb125295abeba2b69356959d97076ddf4`
- Foundation simulation: `0xe02e538b153b500a6b10108a02ecebaae66e56e98cbd67fd4eca2a82271539e1`

Calculated as explained in the nested validation doc:

```sh
cast index address 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 8 # council
# 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
cast index bytes32 0x0af66a3041f2a03ec6be4670bf99f9d62a2f1df568e4c7c9887b7ed904f9a2d0 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
# 0x35d41534d61288843aa236a83f96b8a0272ee0af5963584eb1d12142773dc680
```

```sh
cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8 # foundation
# 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
cast index bytes32 0xe92dca5c9b35e835d553df844235c19cb11171735fc4e244520f5e894452bded 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
# 0x6f51434c2e6c7008d9684c11ac52927556e83fbf7c77675d2151a3b27cde82d0
```

## State Changes

### `0xA3cAB0126d5F504B071b81a3e8A2BBBF17930d86` (`SystemConfigProxy` on zora mainnet)

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x000000000000000000000000B0F15106fa1e473Ddb39790f197275BC979Aa37e`
- **Meaning**: Slot at keccak(systemconfig.disputegamefactory)-1 set to address of
  DisputeGameFactoryProxy deployed via upgrade script

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
- **Before**: `0x0000000000000000000000002615b481bd3e5a1c0c7ca3da1bdc663e8615ade9`
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
