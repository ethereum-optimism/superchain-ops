# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:
1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Worldchain Mainnet Proxy Admin Owner (`0xA4fB12D15Eb85dc9284a7df0AdBC8B696EdbbF1d`)
>
> - Domain Hash:  `0xb38a131bd7616105e60b1765f40d80d946e7ccf096e2a816236d7d819746a870`
> - Message Hash: `0x43d626041d9a39ac1bd75e6b1fbdb8363f79dc8344b04ebb6680a2bf63cc49e5`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x9f6161b6824fe0e61690575dafac8d998222aa6c44bb1bbc700ff397d7d850df`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../../SINGLE-VALIDATION.md) file.

### Task State Changes
---

### [`0x069c4c579671f8c120b1327a73217d01ea2ec5ea`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/worldchain.toml#L63) (DisputeGameFactory) - Chain ID: 480

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** [`0xA4fB12D15Eb85dc9284a7df0AdBC8B696EdbbF1d`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/worldchain.toml#L43)
  - **After:** [`0x6aACd82e5D5A41aC508D456a151Ec53d2b1Fd7ab`](https://oplabs-pbc.slack.com/archives/C088FSUEWGK/p1748899817792179?thread_ts=1747234632.149739&cid=C088FSUEWGK)
  - **Summary:** DisputeGameFactory owner update to new 2-of-2 OP Foundation-Worldchain Safe
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
    
    ```bash
    cast storage 0x069c4c579671f8c120b1327a73217d01ea2ec5ea 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url mainnet
    # returns 0x000000000000000000000000a4fb12d15eb85dc9284a7df0adbc8b696edbbf1d
    cast call 0x069c4c579671f8c120b1327a73217d01ea2ec5ea "owner()(address)" --rpc-url mainnet
    # returns 0xA4fB12D15Eb85dc9284a7df0AdBC8B696EdbbF1d
    ```
  ---
  
### [`0x4e6de8b4c2d5ad6c603648f78311a21558d37a53`](https://etherscan.io/address/0x4E6dE8B4c2D5aD6c603648f78311a21558D37A53) (DelayedWETH) - Chain ID: 480

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** [`0xB2aa0C2C4fD6BFCBF699d4c787CD6Cc0dC461a9d`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/worldchain.toml#L42)
  - **After:** [`0x6aACd82e5D5A41aC508D456a151Ec53d2b1Fd7ab`](https://oplabs-pbc.slack.com/archives/C088FSUEWGK/p1748899817792179?thread_ts=1747234632.149739&cid=C088FSUEWGK)
  - **Summary:** Permissioned DelayedWETH owner update to new 2-of-2 OP Foundation-Worldchain Safe
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
    
    ```bash
    cast storage 0x4e6de8b4c2d5ad6c603648f78311a21558d37a53 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url mainnet
    # returns 0x000000000000000000000000b2aa0c2c4fd6bfcbf699d4c787cd6cc0dc461a9d
    cast call 0x4e6de8b4c2d5ad6c603648f78311a21558d37a53 "owner()(address)" --rpc-url mainnet
    # returns 0xB2aa0C2C4fD6BFCBF699d4c787CD6Cc0dC461a9d
    ```
  ---
  
### [`0xa4fb12d15eb85dc9284a7df0adbc8b696edbbf1d`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/worldchain.toml#L43C14-L43C15) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 480

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `30` - (`cast --to-dec 0x1e` is `30`)
  - **After:** `31` - (`cast --to-dec 0x1f` is `31`)
  - **Summary:** nonce
  - **Detail:** Nonce update for the parent multisig.
  
  ---
  
### [`0xd7405be7f3e63b094af6c7c23d5ee33fd82f872d`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/worldchain.toml#L43C14-L43C15) (ProxyAdmin) - Chain ID: 480

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** [`0xA4fB12D15Eb85dc9284a7df0AdBC8B696EdbbF1d`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/worldchain.toml#L43C14-L43C15)
  - **After:** [`0x6aACd82e5D5A41aC508D456a151Ec53d2b1Fd7ab`](https://oplabs-pbc.slack.com/archives/C088FSUEWGK/p1748899817792179?thread_ts=1747234632.149739&cid=C088FSUEWGK)
  - **Summary:** DisputeGameFactory owner update to new 2-of-2 OP Foundation-Worldchain Safe
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
    
    ```bash
    cast storage 0xd7405be7f3e63b094af6c7c23d5ee33fd82f872d 0x0000000000000000000000000000000000000000000000000000000000000000 --rpc-url mainnet
    # returns 0x000000000000000000000000a4fb12d15eb85dc9284a7df0adbc8b696edbbf1d
    cast call 0xd7405be7f3e63b094af6c7c23d5ee33fd82f872d "owner()(address)" --rpc-url mainnet
    # returns 0xA4fB12D15Eb85dc9284a7df0AdBC8B696EdbbF1d
    ```
