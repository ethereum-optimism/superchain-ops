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
> - Domain Hash: `2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `32c2e453d52e98a2fba9b805b4cf69ed1844ba3b3fe1586daa36239d4db5166d`

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
    Who:               0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD
    Contract:          OptimismPortal2
    Chain ID:          1301
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000035
    Raw Old Value:     0x0000000000000000000000e7e23eba32a6fd2ac79dd5ec72fe7f6217b41bdc00
    Raw New Value:     0x0000000000000000000000c2be75506d5724086deb7245bd260cc9753911be00
    Decoded Kind:      bool
    Decoded Old Value: false
    Decoded New Value: false
    Summary:           spacer_53_0_1
    Detail:            
    
  ----- DecodedStateDiff[1] -----
    Who:               0x448A37330A60494E666F6DD60aD48d930AEbA381
    Contract:          L1CrossDomainMessenger
    Chain ID:          1301
    Raw Slot:          0x00000000000000000000000000000000000000000000000000000000000000fb
    Raw Old Value:     0x000000000000000000000000e7e23eba32a6fd2ac79dd5ec72fe7f6217b41bdc
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    Decoded Kind:      contract ISuperchainConfig
    Decoded Old Value: 
    Decoded New Value: 
    Summary:           superchainConfig
    Detail:            
    
  ----- DecodedStateDiff[2] -----
    Who:               0x4696b5e042755103fe558738Bcd1ecEe7A45eBfe
    Contract:          L1ERC721Bridge
    Chain ID:          1301
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000032
    Raw Old Value:     0x000000000000000000000000e7e23eba32a6fd2ac79dd5ec72fe7f6217b41bdc
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    Decoded Kind:      contract ISuperchainConfig
    Decoded Old Value: 
    Decoded New Value: 
    Summary:           superchainConfig
    Detail:            
    
  ----- DecodedStateDiff[3] -----
    Who:               0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae
    Contract:          
    Chain ID:          
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000068
    Raw Old Value:     0x000000000000000000000000e7e23eba32a6fd2ac79dd5ec72fe7f6217b41bdc
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    [WARN] Slot was not decoded
    
  ----- DecodedStateDiff[4] -----
    Who:               0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c
    Contract:          
    Chain ID:          
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000068
    Raw Old Value:     0x000000000000000000000000e7e23eba32a6fd2ac79dd5ec72fe7f6217b41bdc
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    [WARN] Slot was not decoded
    
  ----- DecodedStateDiff[5] -----
    Who:               0xd363339eE47775888Df411A163c586a8BdEA9dbf
    Contract:          ProxyAdminOwner (GnosisSafe)
    Chain ID:          1301
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
    Raw Old Value:     0x000000000000000000000000000000000000000000000000000000000000001a
    Raw New Value:     0x000000000000000000000000000000000000000000000000000000000000001b
    Decoded Kind:      uint256
    Decoded Old Value: 26
    Decoded New Value: 27
    Summary:           nonce
    Detail:            
    
  ----- DecodedStateDiff[6] -----
    Who:               0xea58fcA6849d79EAd1f26608855c2D6407d54Ce2
    Contract:          L1StandardBridge
    Chain ID:          1301
    Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000032
    Raw Old Value:     0x000000000000000000000000e7e23eba32a6fd2ac79dd5ec72fe7f6217b41bdc
    Raw New Value:     0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be
    Decoded Kind:      contract ISuperchainConfig
    Decoded Old Value: 
    Decoded New Value: 
    Summary:           superchainConfig
    Detail:            
  </code>
 </pre>
