# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

- [Validation](#validation)
  - [Expected Domain and Message Hashes](#expected-domain-and-message-hashes)
- [State Validations](#state-validations)
    - [Task State Changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Single Safe Signer Data
>
> - Domain Hash: `3fe636801465d1c181289f70f03d57edc6aa3fa94e8dd619705c296e2f7ad372`
> - Message Hash: `e87a25205ee4902da83dcf0aa8f45e9a7bb59b1e768a0450aa22b6ce0aca1ed0`

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
    Who:               0xc3aa33D126E36B9331c9E171eD2c5c2d101e76Bd
    Contract:          OptimismPortal2
    Chain ID:          1301
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000035
    Raw Old Value:     0x00000000000000000000001bf3d91f41c2fae8da011194600b5722aff4eec900
    Raw New Value:     0x0000000000000000000000c2be75506d5724086deb7245bd260cc9753911be00
    Decoded Kind:      bool
    Decoded Old Value: false
    Decoded New Value: false
    Summary:           spacer_53_0_1
    Detail:            
    
  ----- DecodedStateDiff[1] -----
    Who:               0xee0Ce4029aC13D3E5ac77a8C96b15940cE70ea2e
    Contract:          L1CrossDomainMessenger
    Chain ID:          1301
    Raw Slot:          0x00000000000000000000000000000000000000000000000000000000000000fb
    Raw Old Value:     0x0000000000000000000000001bf3d91f41c2fae8da011194600b5722aff4eec9
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    Decoded Kind:      contract ISuperchainConfig
    Decoded Old Value: 
    Decoded New Value: 
    Summary:           superchainConfig
    Detail:            
    
  ----- DecodedStateDiff[2] -----
    Who:               0xeF6af6FaC366Bfb518cb6014694ba7dDF4eD5E3c
    Contract:          L1ERC721Bridge
    Chain ID:          1301
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000032
    Raw Old Value:     0x0000000000000000000000001bf3d91f41c2fae8da011194600b5722aff4eec9
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    Decoded Kind:      contract ISuperchainConfig
    Decoded Old Value: 
    Decoded New Value: 
    Summary:           superchainConfig
    Detail:            
    
  ----- DecodedStateDiff[3] -----
    Who:               0xDd61fA7699F0FE78c2cE8BDa113EAe128f7a90d7
    Contract:          
    Chain ID:          
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000068
    Raw Old Value:     0x0000000000000000000000001bf3d91f41c2fae8da011194600b5722aff4eec9
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    [WARN] Slot was not decoded
    
  ----- DecodedStateDiff[4] -----
    Who:               0x9b45Ddec06abc7552B23dC87baDD4756CE0A1EC0
    Contract:          
    Chain ID:          
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000068
    Raw Old Value:     0x0000000000000000000000001bf3d91f41c2fae8da011194600b5722aff4eec9
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    [WARN] Slot was not decoded
    
  ----- DecodedStateDiff[5] -----
    Who:               0xf66d0913Ee7f8518841Ae913853301Dd29b82298
    Contract:          ProxyAdminOwner (GnosisSafe)
    Chain ID:          22444422
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
    Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000019
    Raw New Value:     0x000000000000000000000000000000000000000000000000000000000000001a
    Decoded Kind:      uint256
    Decoded Old Value: 25
    Decoded New Value: 26
    Summary:           nonce
    Detail:            
    
  ----- DecodedStateDiff[6] -----
    Who:               0xea58fcA6849d79EAd1f26608855c2D6407d54Ce2
    Contract:          L1StandardBridge
    Chain ID:          1301
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000032
    Raw Old Value:     0x0000000000000000000000001bf3d91f41c2fae8da011194600b5722aff4eec9
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    Decoded Kind:      contract ISuperchainConfig
    Decoded Old Value: 
    Decoded New Value: 
    Summary:           superchainConfig
    Detail:            
  </code>
 </pre>
