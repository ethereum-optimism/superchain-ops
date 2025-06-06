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

- **DisputeGameFactoryProxy**: `0x7BFfF391A2dbbDc68A259792AC9748F50FcDE93E`
- **AnchorStateRegistryProxy**: `0x0aE6D23501C8078E077133bb30449107eEe7afaD`
- **AnchorStateRegistryImpl**: `0x651Cc14ff8D3F2858A077b5eE26F68b5c06c7b7d`
- **PermissionedDelayedWETHProxy**: `0x953C004e1FE1aD38ec8Ca614CcDC0fd675FFc7e2`
- **PermissionedDisputeGame**: `0x044CEC24Be9DFDd9c65DAC10059a13Fe0f617a5D`

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x6e4b8104d1fa100896d3c6be742be00b5fb1c923ed7696fa8213692977922aa5`
>
> ### Optimism Foundation
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x2e9b9c8942a41bb7417c475995a68eccf31980e45f57260f6d1a81c4b459eb77`

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md) for the expected
state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the
simulation is:

- Council simulation: `0x48468489ca22b3b2d9a20840d27957e37eba44fc864e92a56c1f86f91a0db7ea`
- Foundation simulation: `0x23bfd7d3ada173f36e8447af047bf171da47b14db6be8add99c52f70ce72c9a5`

## State Changes

### `0x7BD909970B0EEdcF078De6Aeff23ce571663b8aA` (`SystemConfigProxy` on Metal Mainnet)

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x0000000000000000000000007BFfF391A2dbbDc68A259792AC9748F50FcDE93E`
- **Meaning**: Slot at keccak(systemconfig.disputegamefactory)-1 set to address of
  DisputeGameFactoryProxy deployed via upgrade script

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
- **Before**: `0x0000000000000000000000003B1F7aDa0Fcc26B13515af752Dd07fB1CAc11426`
- **After**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **Meaning**: Slot at keccak(systemconfig.l2outputoracle)-1 deleted

### `0x3F37aBdE2C6b5B2ed6F8045787Df1ED1E3753956` (`OptimismPortalProxy` on Metal Mainnet)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000038`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x0000000000000000000000007bfff391a2dbbdc68a259792ac9748f50fcde93e`
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
