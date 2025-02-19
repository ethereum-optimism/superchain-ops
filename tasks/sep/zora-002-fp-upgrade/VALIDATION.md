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
cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8 # council
# 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
cast index bytes32 0x0af66a3041f2a03ec6be4670bf99f9d62a2f1df568e4c7c9887b7ed904f9a2d0 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
# 0x6ddce46c849f3c4f07b6936372b065bbb125295abeba2b69356959d97076ddf4
```

```sh
cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8 # foundation
# 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
cast index bytes32 0x0af66a3041f2a03ec6be4670bf99f9d62a2f1df568e4c7c9887b7ed904f9a2d0 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
# 0xe02e538b153b500a6b10108a02ecebaae66e56e98cbd67fd4eca2a82271539e1
```

## State Changes

### `0xB54c7BFC223058773CF9b739cC5bd4095184Fb08` (`SystemConfigProxy` on op-sepolia)

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x000000000000000000000000A983A71253Eb74e5E86A4E4eD9F37113FC25f2BF`
- **Meaning**: Slot at keccak(systemconfig.disputegamefactory)-1 set to address of
  DisputeGameFactoryProxy deployed via upgrade script

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
- **Before**: `0x0000000000000000000000002615b481bd3e5a1c0c7ca3da1bdc663e8615ade9`
- **After**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **Meaning**: Slot at keccak(systemconfig.l2outputoracle)-1 deleted

### `0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f` (`OptimismPortalProxy` on op-sepolia)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000038`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x000000000000000000000000A983A71253Eb74e5E86A4E4eD9F37113FC25f2BF`
- **Meaning**: DisputeGameFactory address variable set to the address deployed in upgrade script

- **Key**: `0x000000000000000000000000000000000000000000000000000000000000003b`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x00000000000000000000000000000000000000000000000TIMESTAMP00000001`
- **Meaning**: Sets the respectedGameType to 1 (permissioned game) and sets the
  respectedGameTypeUpdatedAt timestamp to the time when the upgrade transaction was executed (will
  be a dynamic value)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
- **Before**: `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589`
- **After**: `0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233`
- **Meaning**: Implementation address changed to 0x35028bae87d71cbc192d545d38f960ba30b4b233

### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (`SystemOwnerSafe` on op-sepolia)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005`
- **Before**: `0x000000000000000000000000000000000000000000000000000000000000001f`
- **After**: `0x0000000000000000000000000000000000000000000000000000000000000020`
- **Meaning**: Nonce bumped by 1 in the SystemOwnerSafe
