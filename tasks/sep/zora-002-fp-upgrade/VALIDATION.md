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

## State Overrides

### SystemOwnerSafe (0x1Eb2fFc903729a0F03966B917003800b145F56E2)

- Key: 0x0000000000000000000000000000000000000000000000000000000000000004
  - Value: 0x0000000000000000000000000000000000000000000000000000000000000001
  - Description: Enables the simulation by setting signing threshold to 1

## State Changes

### SystemConfigProxy (0xB54c7BFC223058773CF9b739cC5bd4095184Fb08)

- Key: 0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906
  - Value: 0x000000000000000000000000A983A71253Eb74e5E86A4E4eD9F37113FC25f2BF
  - Description: Slot at keccak(systemconfig.disputegamefactory)-1 set to address of DisputeGameFactoryProxy deployed via upgrade script
- Key: 0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815
  - Value: 0x0000000000000000000000000000000000000000000000000000000000000000
  - Description: Slot at keccak(systemconfig.l2outputoracle)-1 deleted

### OptimismPortalProxy (0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f)

- Key: 0x0000000000000000000000000000000000000000000000000000000000000038
  - Value: 0x000000000000000000000000A983A71253Eb74e5E86A4E4eD9F37113FC25f2BF
  - Description: DisputeGameFactory address variable set to the address deployed in upgrade script
- Key: 0x000000000000000000000000000000000000000000000000000000000000003b
  - Value: 0x00000000000000000000000000000000000000000000000TIMESTAMP00000001
  - Description: Sets the respectedGameType to 1 (permissioned game) and sets the respectedGameTypeUpdatedAt timestamp to the time when the upgrade transaction was executed (will be a dynamic value)
- Key: 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  - Value: 0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233
  - Description: Implementation address changed to 0x35028bae87d71cbc192d545d38f960ba30b4b233

### SystemOwnerSafe (0x1Eb2fFc903729a0F03966B917003800b145F56E2)

- Key: 0x0000000000000000000000000000000000000000000000000000000000000005
  - Value: increment
  - Description: Nonce bumped by 1 in the SystemOwnerSafe
