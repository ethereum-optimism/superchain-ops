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

- **DisputeGameFactoryProxy**: `0xd9A68F90B2d2DEbe18a916859B672D70f79eEbe3`
- **AnchorStateRegistryProxy**: `0x716C6380EC3FEA335F836aF88eBCe759cb689556`
- **AnchorStateRegistryImpl**: `0xcbFb8Dc362567b983F315AcF74d2A2fcb5aB1C08`
- **PermissionedDelayedWETHProxy**: `0x24CD15F9b106354Fa27a30673f7FE5fe623A0807`
- **PermissionedDisputeGame**: `0x20A834F75Df0c2510D007D60a98DB1D33e3c13C6`

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xe1d297426d1b57746057a3d428ffadfb3c862db6e32cfd7dc20a9d85d5def229`
>
> ### Optimism Foundation
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xca857fea43e77d47a9c532d21fe90d48ab0c5b1139a8965c84eae06a43d970bd`

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md) for the expected
state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the
simulation is:

- Council simulation: `0xfc81ea3c0f39e55f586387d93ae839a4c62f14618270a57d36ba9f54965d7b97`
- Foundation simulation: `0xe75db316c16d1eaf3afeac041b03495f105d3c29774143e761892eaf5bed2eb0`

## State Changes

### `0x5D63A8Dc2737cE771aa4a6510D063b6Ba2c4f6F2` (`SystemConfigProxy` on Metal Sepolia)

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x000000000000000000000000d9A68F90B2d2DEbe18a916859B672D70f79eEbe3`
- **Meaning**: Slot at keccak(systemconfig.disputegamefactory)-1 set to address of
  DisputeGameFactoryProxy deployed via upgrade script

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
- **Before**: `0x00000000000000000000000075a6B961c8da942Ee03CA641B09C322549f6FA98`
- **After**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **Meaning**: Slot at keccak(systemconfig.l2outputoracle)-1 deleted

### `0x01D4dfC994878682811b2980653D03E589f093cB` (`OptimismPortalProxy` on Metal Sepolia)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000038`
- **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
- **After**: `0x000000000000000000000000d9a68f90b2d2debe18a916859b672d70f79eebe3`
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
