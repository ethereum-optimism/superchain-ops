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
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xcedbef00e8b71f0cc711f32fe6dd303bcd5430ca36bfb66c6197ad120e790cc3`

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
  Who:               0x034edD2A225f7f429A63E0f1D2084B9E0A93b538
  Contract:          SystemConfig
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Raw New Value:     0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647
  Decoded Kind:      address
  Decoded Old Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Decoded New Value: 0x340f923E5c7cbB2171146f64169EC9d5a9FfE647
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[1] -----
  Who:               0x05C993e60179f28bF649a2Bb5b00b5F4283bD525
  Contract:          SystemConfig
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Raw New Value:     0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647
  Decoded Kind:      address
  Decoded Old Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Decoded New Value: 0x340f923E5c7cbB2171146f64169EC9d5a9FfE647
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[2] -----
  Who:               0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1
  Contract:          DisputeGameFactory
  Chain ID:          11155420
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x0000000000000000000000007717296cac5d39d362eb77a94c95483bebae214e
  Raw New Value:     0x000000000000000000000000845e5382d60ec16e538051e1876a985c5339cc62
  [WARN] Slot was not decoded

----- DecodedStateDiff[3] -----
  Who:               0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1
  Contract:          DisputeGameFactory
  Chain ID:          11155420
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x0000000000000000000000001851253ad7214f7b39e541befb6626669cb2446f
  Raw New Value:     0x000000000000000000000000d46b939123d5fb1b48ee3f90caebc9d5498ed542
  [WARN] Slot was not decoded

----- DecodedStateDiff[4] -----
  Who:               0x16Fc5058F25648194471939df75CF27A2fdC48BC
  Contract:          OptimismPortal2
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Raw New Value:     0x000000000000000000000000b443da3e07052204a02d630a8933dac05a0d6fb4
  Decoded Kind:      address
  Decoded Old Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Decoded New Value: 0xB443Da3e07052204A02d630a8933dAc05a0d6fB4
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[5] -----
  Who:               0x1Eb2fFc903729a0F03966B917003800b145F56E2
  Contract:          ProxyAdminOwner (GnosisSafe)
  Chain ID:          11155420
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000005
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000019
  Raw New Value:     0x000000000000000000000000000000000000000000000000000000000000001a
  Decoded Kind:      uint256
  Decoded Old Value: 25
  Decoded New Value: 26
  Summary:           nonce
  Detail:

----- DecodedStateDiff[6] -----
  Who:               0x2bfb22cd534a462028771a1cA9D6240166e450c4
  Contract:          L1ERC721Bridge
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Raw New Value:     0x0000000000000000000000007ae1d3bd877a4c5ca257404ce26be93a02c98013
  Decoded Kind:      address
  Decoded Old Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Decoded New Value: 0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[7] -----
  Who:               0x33f60714BbD74d62b66D79213C348614DE51901C
  Contract:          L1StandardBridge
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Raw New Value:     0x0000000000000000000000000b09ba359a106c9ea3b181cbc5f394570c7d2a7a
  Decoded Kind:      address
  Decoded Old Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Decoded New Value: 0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[8] -----
  Who:               0x3454F9df5E750F1383e58c1CB001401e7A4f3197
  Contract:          AddressManager
  Chain ID:          763373
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  Raw New Value:     0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b
  [WARN] Slot was not decoded

----- DecodedStateDiff[9] -----
  Who:               0x4Ca9608Fef202216bc21D543798ec854539bAAd3
  Contract:          SystemConfig
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000760c48c62a85045a6b69f07f4a9f22868659cbcc
  Raw New Value:     0x000000000000000000000000340f923e5c7cbb2171146f64169ec9d5a9ffe647
  Decoded Kind:      address
  Decoded Old Value: 0x760C48C62A85045A6B69f07F4a9f22868659CbCc
  Decoded New Value: 0x340f923E5c7cbB2171146f64169EC9d5a9FfE647
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[10] -----
  Who:               0x5c1d29C6c9C8b0800692acC95D700bcb4966A1d7
  Contract:          OptimismPortal2
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Raw New Value:     0x000000000000000000000000b443da3e07052204a02d630a8933dac05a0d6fb4
  Decoded Kind:      address
  Decoded Old Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Decoded New Value: 0xB443Da3e07052204A02d630a8933dAc05a0d6fB4
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[11] -----
  Who:               0x5f5a404A5edabcDD80DB05E8e54A78c9EBF000C2
  Contract:          L1StandardBridge
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Raw New Value:     0x0000000000000000000000000b09ba359a106c9ea3b181cbc5f394570c7d2a7a
  Decoded Kind:      address
  Decoded Old Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Decoded New Value: 0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[12] -----
  Who:               0x65ea1489741A5D72fFdD8e6485B216bBdcC15Af3
  Contract:          OptimismPortal2
  Chain ID:          1946
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x0000000000000000000000002d7e764a0d9919e16983a46595cfa81fc34fa7cd
  Raw New Value:     0x000000000000000000000000b443da3e07052204a02d630a8933dac05a0d6fb4
  Decoded Kind:      address
  Decoded Old Value: 0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd
  Decoded New Value: 0xB443Da3e07052204A02d630a8933dAc05a0d6fB4
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[13] -----
  Who:               0x6e8A77673109783001150DFA770E6c662f473DA9
  Contract:          AddressManager
  Chain ID:          1946
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  Raw New Value:     0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b
  [WARN] Slot was not decoded

----- DecodedStateDiff[14] -----
  Who:               0x860e626c700AF381133D9f4aF31412A2d1DB3D5d
  Contract:          DisputeGameFactory
  Chain ID:          763373
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x00000000000000000000000065e5ec10f922cf7e61ead974525a2795bd4fda9a
  Raw New Value:     0x000000000000000000000000de2b69153c42191eb4863a36024d80a1d426d0c8
  [WARN] Slot was not decoded

----- DecodedStateDiff[15] -----
  Who:               0x860e626c700AF381133D9f4aF31412A2d1DB3D5d
  Contract:          DisputeGameFactory
  Chain ID:          763373
  Raw Slot:          0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
  Raw Old Value:     0x00000000000000000000000043736de4bd35482d828b79ea673b76ab1699626f
  Raw New Value:     0x0000000000000000000000000c356f533eb009deb302bc96522e80dea6a16276
  [WARN] Slot was not decoded

----- DecodedStateDiff[16] -----
  Who:               0x9bFE9c5609311DF1c011c47642253B78a4f33F4B
  Contract:          AddressManager
  Chain ID:          11155420
  Raw Slot:          0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
  Raw Old Value:     0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231
  Raw New Value:     0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b
  [WARN] Slot was not decoded

----- DecodedStateDiff[17] -----
  Who:               0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01
  Contract:          DisputeGameFactory
  Chain ID:          1946
  Raw Slot:          0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
  Raw Old Value:     0x0000000000000000000000002087cbc6ec893a31405d56025cd1ae648da3982c
  Raw New Value:     0x000000000000000000000000697a4684576d8a76d4b11e83e9b6f3b61bf04755
  [WARN] Slot was not decoded

----- DecodedStateDiff[18] -----
  Who:               0xd1C901BBD7796546A7bA2492e0E199911fAE68c7
  Contract:          L1ERC721Bridge
  Chain ID:          763373
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Raw New Value:     0x0000000000000000000000007ae1d3bd877a4c5ca257404ce26be93a02c98013
  Decoded Kind:      address
  Decoded Old Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Decoded New Value: 0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[19] -----
  Who:               0xd83e03D576d23C9AEab8cC44Fa98d058D2176D1f
  Contract:          L1ERC721Bridge
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x000000000000000000000000276d3730f219f7ec22274f7263180b8452b46d47
  Raw New Value:     0x0000000000000000000000007ae1d3bd877a4c5ca257404ce26be93a02c98013
  Decoded Kind:      address
  Decoded Old Value: 0x276d3730f219f7ec22274f7263180b8452B46d47
  Decoded New Value: 0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[20] -----
  Who:               0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1
  Contract:          L1StandardBridge
  Chain ID:          11155420
  Raw Slot:          0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  Raw Old Value:     0x00000000000000000000000078972e88ab8bbb517a36caea23b931bab58ad3c6
  Raw New Value:     0x0000000000000000000000000b09ba359a106c9ea3b181cbc5f394570c7d2a7a
  Decoded Kind:      address
  Decoded Old Value: 0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6
  Decoded New Value: 0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A
  Summary:           ERC-1967 implementation slot
  Detail:            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

----- DecodedStateDiff[21] -----
  Who:               0xfBceeD4DE885645fBdED164910E10F52fEBFAB35
  Contract:
  Chain ID:
  Raw Slot:          0x0000000000000000000000000000000000000000000000000000000000000001
  Raw Old Value:     0x0000000000000000000000000000000000000000000000000000000000000001
  Raw New Value:     0x0000000000000000000000000000000000000000000000000000000000000000
  [WARN] Slot was not decoded 
  </code>
 </pre>
