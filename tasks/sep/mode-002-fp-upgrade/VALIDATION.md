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

## Predeploys

- **DisputeGameFactoryProxy**: `0x7Bb634B42373A87712Da14064deD13Db8b8b14f4`
- **AnchorStateRegistryProxy**: `0x5C30E13389686AE0ddF41859FbD4BD2CBE2Aaf1D`
- **AnchorStateRegistryImpl**: `0x43c0EA5cf1614a3F16b51804F3283f95d09a903f`
- **PermissionedDelayedWETHProxy**: `0xD92Bf98a4049097C4b2288734748dce90803E1C1`
- **PermissionedDisputeGame**: `0xdC0c2Cb09512490B0b81292b9153415C3f092D4b`

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xbc522fd52b91ac9639f0058838fadfa2ef69ed5ba7937cdeb220a44cf8d70bf1`
>
> ### Optimism Foundation
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x1dfa5b291917dc6fa60b42a0d8dc0e928f2c83524beac422454070bae22620c0`

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md) for the expected
state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the
simulation is:

- Council simulation: `0xc8975897b3a17dd64187fa6ed2bab49497341305f1b6a2e7f2e53dbe56217eb4`
- Foundation simulation: `0x7023b0002c2f5b2122afd072918fee774d8f036da616618afaf3b870bac96692`

## State Changes

### `0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2` (`SystemConfigProxy` on Mode Sepolia)

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x0000000000000000000000007bb634b42373a87712da14064ded13db8b8b14f4`
- **Meaning**: Slot at keccak(systemconfig.disputegamefactory)-1 set to address of
  DisputeGameFactoryProxy deployed via upgrade script

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
- **Before**: `0x0000000000000000000000002634BD65ba27AB63811c74A63118ACb312701Bfa`
- **After**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **Meaning**: Slot at keccak(systemconfig.l2outputoracle)-1 deleted

### `0x320e1580effF37E008F1C92700d1eBa47c1B23fD` (`OptimismPortalProxy` on Mode Sepolia)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000038`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x0000000000000000000000007bb634b42373a87712da14064ded13db8b8b14f4`
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
- **Meaning**: Implementation address updated
