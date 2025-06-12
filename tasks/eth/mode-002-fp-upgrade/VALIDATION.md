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

- **DisputeGameFactoryProxy**: `0x6f13EFadABD9269D6cEAd22b448d434A1f1B433E`
- **AnchorStateRegistryProxy**: `0xbf1229eE0782939bB4325Fd13a0b481949e311Aa`
- **AnchorStateRegistryImpl**: `0xF027D5B39fB1Ca1A6143e63ea0Be3cc8b099aF7D`
- **PermissionedDelayedWETHProxy**: `0xa29b6D87Ee95375E7a31374667054F38b920ab7a`
- **PermissionedDisputeGame**: `0x75fa114D4286c7d1114CE773EfF0f1bDe0aF966a`

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x2b582eaaf0a5622e1873cddfd5465d7c52e5d417c1b91e56e0415f0927d96c6d`
>
> ### Optimism Foundation
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x2b582eaaf0a5622e1873cddfd5465d7c52e5d417c1b91e56e0415f0927d96c6d`

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md) for the expected
state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the
simulation is:

- Council simulation: `0xba047a04e2244111107d2773cb4f05b37d83bed79351a7e5020741e3bac72750`
- Foundation simulation: `0x3ecb807323c09a0a526cf1a6707f0aa1bbc90eee2dc1926f9f0fc88353611334`

## State Changes

### `0x5e6432F18Bc5d497B1Ab2288a025Fbf9D69E2221` (`SystemConfigProxy` on Mode Mainnet)

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x0000000000000000000000006f13EFadABD9269D6cEAd22b448d434A1f1B433E`
- **Meaning**: Slot at keccak(systemconfig.disputegamefactory)-1 set to address of
  DisputeGameFactoryProxy deployed via upgrade script

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
- **Before**: `0x0000000000000000000000004317ba146D4933D889518a3e5E11Fe7a53199b04`
- **After**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **Meaning**: Slot at keccak(systemconfig.l2outputoracle)-1 deleted

### `0x8B34b14c7c7123459Cf3076b8Cb929BE097d0C07` (`OptimismPortalProxy` on Mode Mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000038`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x0000000000000000000000006f13efadabd9269d6cead22b448d434a1f1b433e`
- **Meaning**: DisputeGameFactory address variable set to the address deployed in upgrade script

- **Key**: `0x000000000000000000000000000000000000000000000000000000000000003b`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x00000000000000000000000000000000000000000000000TIMESTAMP00000001`
- **Meaning**: Sets the respectedGameType to 1 (permissioned game) and sets the
  respectedGameTypeUpdatedAt timestamp to the time when the upgrade transaction was executed (will
  be a dynamic value)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
- **Before**: `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589`
- **After**: `0x000000000000000000000000e2F826324b2faf99E513D16D266c3F80aE87832B`
- **Meaning**: Implementation address updated
