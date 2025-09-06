# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council Safe (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x4b0bee8620f5b7f05309a629256d0712bb221bbd48022550d790fbb4ec0a6be8`
>
> ### Foundation Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x3917b97c12f07976b85bbe12e0fa51749b6f66d3becead5fdccfb14c006cac51`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x50ba25e651b213f346a091a23a3e8ccde6fc1ea21d45ce9872df7a4f746f50ef`

## Understanding Task Calldata

Calldata:
```
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000004400000000000000000000000006b6f9129efb1b7a48f84e3b787333d1dca02ee340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08000000000000000000000000e17071f4c216eb189437fbdbcc16bb79c4efd9c2039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000000000000000000000000000fbceed4de885645fbded164910e10f52febfab350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08000000000000000000000000e17071f4c216eb189437fbdbcc16bb79c4efd9c203ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000000000000000000000000000fbceed4de885645fbded164910e10f52febfab350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a49a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08000000000000000000000000e17071f4c216eb189437fbdbcc16bb79c4efd9c203682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6000000000000000000000000000000000000000000000000000000000000000000000000000000001ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08000000000000000000000000e17071f4c216eb189437fbdbcc16bb79c4efd9c203eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [<TODO NESTED OR SINGLE>-VALIDATION.md](../../../../../<TODO>) file.

### Task State Changes

#### Decoded Transfer 0
  - **From:**              `0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f`
  - **To:**                `0x55ac772AD5cb517B12B6Ee8f245f76DE6164E288`
  - **Value:**             `23436084376854033702179`
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`
  ━━━━━ Attention: Copy content above this line into the VALIDATION.md file. ━━━━━
  
  TASK STATE CHANGES
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ━━━━━ Attention: Copy content below this line into the VALIDATION.md file. ━━━━━
  
  ---
  
### `0x16b0a4f451c4cb567703367e587e15ac108e4311` (L1ERC721Bridge) - Chain ID: 999999999
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xAE2AF01232a6c4a4d3012C5eC5b1b35059caF10d`
  - **After:** `0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x1bdbc0ae22bec0c2f08b4dd836944b3e28fe9b7a` (L1CrossDomainMessenger) - Chain ID: 999999999
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x1eb2ffc903729a0f03966b917003800b145f56e2` (ProxyAdminOwner (GnosisSafe)) - Chain ID: 11155420
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `32`
  - **After:** `33`
  - **Summary:** nonce
  - **Detail:** 
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x1f0ba133206ad21c5af1b8748fd57705ea914f97` (<TODO: enter contract name>) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2`
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x27c9392144dfcb6dab113f737356c32435cd1d55` (AddressManager) - Chain ID: 999999999
  
- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** `0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65`
  - **After:** `0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x5376f1d543dcbb5bd416c56c189e4cb7399fcccb` (L1StandardBridge) - Chain ID: 999999999
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x64B5a5Ed26DCb17370Ff4d33a8D503f0fbD06CfF`
  - **After:** `0x44AfB7722AF276A601D524F429016A18B6923df0`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x55ac772ad5cb517b12b6ee8f245f76de6164e288` (<TODO: enter contract name>) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb080001`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0x784d2F03593A42A6E4676A012762F18775ecbBe6`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x74696c010b95507fb39e0165ad1b8ec84146e0af3f02eab2608cc6180910586b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2`
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x5f3bdd57f01e88ce2f88f00685d30d6eb51a187c` (OptimismMintableERC20Factory) - Chain ID: 999999999
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xE01efbeb1089D1d1dB9c6c8b135C934C0734c846`
  - **After:** `0x5493f4677A186f64805fe7317D6993ba4863988F`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x646e8d1afc0720642f1df8cfb5c6648f047a9bb0` (<TODO: enter contract name>) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb080001`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000a983a71253eb74e5e86a4e4ed9f37113fc25f2bf`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x9ed1dbf8e56c7895c20e4e64dc1100e09dbbdaac69a1e617a1993c2d7ef1c4f9`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000001c06412`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000000000000000000000000000068bc12b000000001`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0xeb69cC681E8D4a557b30DFFBAd85aFfD47a2CF2E`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2`
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0x6b6f9129efb1b7a48f84e3b787333d1dca02ee34` (<TODO: enter contract name>) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000016`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0xa8fdce8f78ae428b7497ebda3684593a572eafae` (DelayedWETH) - Chain ID: 999999999
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538`
  - **After:** `0x5e40B9231B86984b5150507046e354dbFbeD3d9e`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0xa983a71253eb74e5e86a4e4ed9f37113fc25f2bf` (DisputeGameFactory) - Chain ID: 999999999
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xA51bea7E4d34206c0bCB04a776292F2f19F0BeEc`
  - **After:** `0x33D1e8571a85a538ed3D5A4d88f46C112383439D`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:** `0x0000000000000000000000004f500fe7c59afb843fe47967eb6d0b8be809f066`
  - **After:** `0x000000000000000000000000ebbfceae957136a52a1832ebf4968cafd3614837`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0xb54c7bfc223058773cf9b739cc5bd4095184fb08` (SystemConfig) - Chain ID: 999999999
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000000000000000000000000000000000003b9ac9ff`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x33b83E4C305c908B2Fc181dDa36e230213058d7d`
  - **After:** `0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** `0xA983A71253Eb74e5E86A4E4eD9F37113FC25f2BF`
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address
  - **Detail:** Unstructured storage slot for the address of the DisputeGameFactory proxy.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0xc038e00ad97c249d9613fe1970930a81112af392` (<TODO: enter contract name>) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000c2be75506d5724086deb7245bd260cc9753911be0001`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000a983a71253eb74e5e86a4e4ed9f37113fc25f2bf`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000effe2c6ca9ab797d418f0d91ea60807713f3536f`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x9ed1dbf8e56c7895c20e4e64dc1100e09dbbdaac69a1e617a1993c2d7ef1c4f9`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000001c06412`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0x7b465370BB7A333f99edd19599EB7Fb1c2D3F8D2`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2`
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.
  
**<TODO: Insert links for this state change then remove this line.>**
  
  ---
  
### `0xeffe2c6ca9ab797d418f0d91ea60807713f3536f` (OptimismPortal2) - Chain ID: 999999999
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000646e8d1afc0720642f1df8cfb5c6648f047a9bb0`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000055ac772ad5cb517b12b6ee8f245f76de6164e288`
  - **Summary:** 
  - **Detail:** 
  
**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**
  
**<TODO: Insert links for this state change then remove this line.>**
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x35028bAe87D71cbC192d545d38F960BA30B4B233`
  - **After:** `0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.