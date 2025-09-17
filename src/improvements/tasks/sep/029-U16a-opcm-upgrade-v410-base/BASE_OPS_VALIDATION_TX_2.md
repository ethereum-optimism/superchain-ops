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
> ### Base Operations (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`) - Second Approve Hash Transaction
>
> - Domain Hash:  `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x1efd160c418041038c6a9e0396ed887fdbbf6f11aef6aa0f93a527fb9a8b95d9`
>

# Task State Changes
  
### `0x0fe884546476ddd290ec46318785046ef68a0ba9` (ProxyAdminOwner (GnosisSafe)) - Chain ID: 11763072
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `24`
  - **After:** `25`
  - **Summary:** nonce
  - **Detail:** Proxy admin owner nonce incremented.
  
  ---
  
### `0x21efd066e581fa55ef105170cc04d74386a09190` (L1ERC721Bridge) - Chain ID: 84532
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized`, `_initializing` and `spacer_0_2_30` share this slot. `initialized` set to 3 from 1. All other values are 0.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000f272670eb55e895584501d564afeb048bed26194`
  - **Summary:** systemConfig address set to OP SystemConfig proxy
  - **Detail:** Storage slot 51 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/sepolia/base.toml#L50)
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **After:** [`0x7f1d12fB2911EB095278085f721e644C1f675696`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-sepolia.toml#L20)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### `0x2ff5cc82dbf333ea30d8ee462178ab1707315355` (AnchorStateRegistry) - Chain ID: 84532
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000f272670eb55e895584501d564afeb048bed261940001`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized`, `_initializing` and `systemConfig` share this slot. `initialized` set to 1 from 0. `systemConfig` is set to [`0xf272670eb55e895584501d564AfEB048bEd26194`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/sepolia/base.toml#L50)
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1`
  - **Summary:** DisputeGameFactory set.
  - **Detail:** The DisputeGameFactory is set at slot 1 as [`0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/sepolia/base.toml#L51)
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x837ec5272320895cab3e8723afc84690bf2bc8851b80d7f81ec2f7f240d0dc5e`
  - **Summary:** `startingAnchorRoot` proposal struct. **THIS VALUE MAY NOT MATCH WHAT YOU SEE IN YOUR SIMULATION - THIS IS EXPECTED.**
  - **Detail:** Storage slot 3 contains the first 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is a Hash. The actual value MAY differ based on the most recently finalized L2 output.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000001d6700a`
  - **Summary:** `startingAnchorRoot` struct second half initialized. **THIS VALUE MAY NOT MATCH WHAT YOU SEE IN YOUR SIMULATION - THIS IS EXPECTED.**
  - **Detail:** Storage slot 4 contains the second 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is an L2 block number.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000000000000000000000000000068c9834400000000`
  - **Summary:** Packed slot with `respectedGameType` and `retirementTimestamp` initialized. **THIS VALUE MAY NOT MATCH WHAT YOU SEE IN YOUR SIMULATION - THIS IS EXPECTED.**
  - **Detail:** The non-zero values should correspond to recent timestamp values, as [set](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L106) in the AnchorStateRegistry's initialize function.
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xeb69cC681E8D4a557b30DFFBAd85aFfD47a2CF2E`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/validation/standard/standard-versions-sepolia.toml#L13)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/extra/addresses/addresses.json#L1263)
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract. This address is the Base ProxyAdmin.
  
  ---
  
### `0x32ce910d9c6c8f78dc6779c1499ab05f281a054e` (DelayedWETH) - Chain ID: 84532
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Storage slot 0 contains the initialization flag for the DelayedWETH contract.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000f272670eb55e895584501d564afeb048bed26194`
  - **Summary:** SystemConfig address set.
  - **Detail:** `systemConfig` is set to [`0xf272670eb55e895584501d564AfEB048bEd26194`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/sepolia/base.toml#L50)
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/extra/addresses/addresses.json#L1263)
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract. This address is the Base ProxyAdmin.
  
  ---
  
### `0x49f53e41452c74589e85ca1677426ba426459e85` (OptimismPortal2) - Chain ID: 84532
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized` and `_initializing` share this slot. `initialized` set to 3 from 1. All other values are 0.
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000002ff5cc82dbf333ea30d8ee462178ab1707315355`
  - **Summary:** Slot 62 set to `anchorStateRegistry`.
  - **Detail:** See AnchorStateRegistry above.
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`
  - **After:** [`0x381E729FF983FA4BCEd820e7b922d79bF653B999`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-sepolia.toml#L12)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---

### `0x6AF0674791925f767060Dd52f7fB20984E8639d8` (Base Operations GnosisSafe)  

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `11`
  - **After:** `12`
  - **Summary:** nonce
  - **Detail:** Gnosis safe nonce incremented.

  ---
  
### `0x709c2b8ef4a9fefc629a8a2c1af424dc5bd6ad1b` (AddressManager) - Chain ID: 84532
  
- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **After:** `0x00000000000000000000000022d12e0faebd62d429514a65ebae32dd316c12d6`
  - **Summary:**  The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v4.1.0-rc.2' L1CrossDomainMessenger at [0x22d12e0faebd62d429514a65ebae32dd316c12d6](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-sepolia.toml#L19).
  - **Detail:** This key is complicated to compute, so instead we attest to correctness of the key by verifying that the "Before" value currently exists in that slot, as explained below. **Before** address matches the following cast call to `AddressManager.getAddres()`:
      - `cast call 0x709c2b8ef4a9fefc629a8a2c1af424dc5bd6ad1b 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia`
      - returns: `0x5D5a095665886119693F0B41d8DFeE78da033e8B`
  
  ---
  
### `0xc34855f4de64f1840e5686e64278da901e261f20` (L1CrossDomainMessenger) - Chain ID: 84532
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000030000000000000000000000000000000000000000`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized`, `_initializing` and `spacer_0_0_20` share this slot. `initialized` (offset 20) set to 3 from 1. All other values are 0.
  
- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000f272670eb55e895584501d564afeb048bed26194`
  - **Summary:** SystemConfig address set.
  - **Detail:** `systemConfig` is set to [`0xf272670eb55e895584501d564AfEB048bEd26194`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/sepolia/base.toml#L50)
  
  ---
  
### `0xd3683e4947a7769603ab6418ec02f000ce3cf30b` (DelayedWETH) - Chain ID: 84532
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Storage slot 0 contains the initialization flag for the DelayedWETH contract.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000f272670eb55e895584501d564afeb048bed26194`
  - **Summary:** SystemConfig address set.
  - **Detail:** `systemConfig` is set to [`0xf272670eb55e895584501d564AfEB048bEd26194`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/sepolia/base.toml#L50)
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/extra/addresses/addresses.json#L1263)
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract. This address is the Base ProxyAdmin.
  
  ---

### `0xd6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1` (DisputeGameFactory) - Chain ID: 84532
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x4bbA758F006Ef09402eF31724203F316ab74e4a0`
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/validation/standard/standard-versions-sepolia.toml#L16)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:** `0x000000000000000000000000f0102ffe22649a5421d53acc96e309660960cf44`
  - **After:** `0x000000000000000000000000217e725700de4dc599360adbd57dbb7de280817e`
  - **Summary:**  Set a new game implementation for game type [PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L55)
  - **Detail:**  This is `gameImpls[1]` -> `0x217e725700de4dc599360adbd57dbb7de280817e`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x000000000000000000000000cfce7dd673fbbbffd16ab936b7245a2f2db31c9a`
  - **After:** `0x00000000000000000000000032b37bbd2c81e853ea098ce45856ae305df10dd1`
  - **Summary:**  Set a new game implementation for game type [CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)
  - **Detail:**  This is `gameImpls[0]` -> `0x32b37bbd2c81e853ea098ce45856ae305df10dd1`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.1.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```
  
  ---
  
### `0xf272670eb55e895584501d564afeb048bed26194` (SystemConfig) - Chain ID: 84532
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized` and `_initializing` share this slot. `initialized` set to 3 from 1. All other values are 0.
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000014a34`
  - **Summary:** Slot 107 set.
  - **Detail:** L2 ChainID is set to `84532`. i.e. `cast --to-dec 0x14a34`.
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be`
  - **Summary:** Slot 108 set.
  - **Detail:** `superchainConfig` set to [`0xc2be75506d5724086deb7245bd260cc9753911be`](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/sepolia/superchain.toml#L3).
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xfdA350e8038728B689976D4A9E8A318400A150C5`
  - **After:** [`0x2bFE4A5Bd5A41e9d848d843ebCDFa15954e9A557`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-sepolia.toml#L8)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address
  - **Detail:** DisputeGameFactory proxy address cleared (legacy slot deprecated)
  
  ---
  
### `0xfd0bf71f60660e2f608ed56e1659c450eb113120` (L1StandardBridge) - Chain ID: 84532
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Summary:** Multiple variables share this storage slot. Details below.
  - **Detail:** `_initialized`, `_initializing` and `spacer_0_2_30` share this slot. `initialized` set to 3 from 1. All other values are 0.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000f272670eb55e895584501d564afeb048bed26194`
  - **Summary:** Set slot 52.
  - **Detail:** Storage slot 52 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/d56233c1e5254fc2fd769d5b33269502a1fe9ef8/superchain/configs/sepolia/base.toml#L50)
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`
  - **After:** [`0xe32B192fb1DcA88fCB1C56B3ACb429e32238aDCb`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/validation/standard/standard-versions-sepolia.toml#L21)
  - **Summary:** ERC-1967 implementation slot
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
