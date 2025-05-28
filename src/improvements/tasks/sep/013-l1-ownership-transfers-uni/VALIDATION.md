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
> ### Unichain Proxy Admin Owner (`0xd363339eE47775888Df411A163c586a8BdEA9dbf`)
>
> - Domain Hash:  `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0x43788c59fcdd0d94cd9713ab9eb86f9e6f642857a7e2d7c24eeab06c6e7f5a7f`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xfc963d90302e3149c58ca0dd63de1988a9fd4d2255d65e00741c7f20f1b65ff4`

## Understanding Task Calldata

The commands to encode the calldata is:

First lets define all the contracts that will have their ownership transferred:
- DisputeGameFactoryProxy: [`0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L65)
- Permissioned DelayedWETHProxy: [`0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L64)
- Permissionless DelayedWETHProxy: `0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae` - This address is not referenced in the superchain registry so we show how to manually retrieve it below.
    ```bash
    # Call the DisputeGameFactoryProxy to get the Permissionless FDG - https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L65C30-L65C72
    cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 0 --rpc-url sepolia
    # returns 0xA84cF3aAB33A5Ac812F46A46601b0E39A03E07F1
    # Call weth on the Permissionless FDG to get the Permissionless DelayedWETHProxy
    cast call 0xA84cF3aAB33A5Ac812F46A46601b0E39A03E07F1 "weth()(address)" --rpc-url sepolia
    # returns 0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae
    ```
- ProxyAdmin: [`0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L61)

Then we know that we call `transferOwnership` on each of these contracts with the new owner being [`0x1eb2ffc903729a0f03966b917003800b145f56e2`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/op.toml#L46).
Therefore, this calldata should be encoded as:

```bash
cast calldata 'transferOwnership(address)' 0x1eb2ffc903729a0f03966b917003800b145f56e2
# returns 0xf2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2
```

Now we can encode the final calldata as:
```
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b, false, 0, 0xf2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2),(0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c, false, 0, 0xf2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2),(0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae, false, 0, 0xf2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2),(0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4, false, 0, 0xf2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2)]"
```

The resulting calldata:
```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000002400000000000000000000000000000000000000000000000000000000000000320000000000000000000000000eff73e5aa3b9aec32c659aa3e00444d20a84394b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e20000000000000000000000000000000000000000000000000000000000000000000000000000000073d18d6caa14aeec15449d0a25a31d4e7e097a5c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2000000000000000000000000000000000000000000000000000000000000000000000000000000004e7e6dc46ce003a1e353b6848bf5a4fc1feac8ae0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2000000000000000000000000000000000000000000000000000000000000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e200000000000000000000000000000000000000000000000000000000
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../../SINGLE-VALIDATION.md) file.

### Task State Changes
  
  ---
  
### [`0x2bf403e5353a7a082ef6bb3ae2be3b866d8d3ea4`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L61) (ProxyAdmin) - Chain ID: 1301
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0xd363339eE47775888Df411A163c586a8BdEA9dbf`
  - **After:** [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/op.toml#L46)
  - **Summary:** ProxyAdmin owner update to new Superchain L1PAO
  
  ---
  
### `0x4e7e6dc46ce003a1e353b6848bf5a4fc1feac8ae` (Permissionless DelayedWETH) - Chain ID: 1301
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** [`0xd363339eE47775888Df411A163c586a8BdEA9dbf`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L46)
  - **After:** [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/op.toml#L46)
  - **Summary:** Permissionless DelayedWETH owner update to new Superchain L1PAO
  - **Detail:** The superchain registry does not have a link for this contract, so we manually retrieved the address from the DisputeGameFactoryProxy.
    ```bash
    # Call the DisputeGameFactoryProxy to get the Permissionless FDG - https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L65C30-L65C72
    cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "gameImpls(uint32)(address)" 0 --rpc-url sepolia
    # returns 0xA84cF3aAB33A5Ac812F46A46601b0E39A03E07F1
    # Call weth on the Permissionless FDG to get the Permissionless DelayedWETHProxy
    cast call 0xA84cF3aAB33A5Ac812F46A46601b0E39A03E07F1 "weth()(address)" --rpc-url sepolia
    # returns 0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae
    ```
    Also you can check that the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
    ```bash
    cast storage 0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url sepolia
    # returns 0x000000000000000000000000d363339ee47775888df411a163c586a8bdea9dbf
    cast call 0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae "owner()(address)" --rpc-url sepolia
    # returns 0xd363339eE47775888Df411A163c586a8BdEA9dbf
    ```
    
  ---
  
### [`0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L64) (Permissioned DelayedWETH) - Chain ID: 1301
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x000000000000000000000000d363339ee47775888df411a163c586a8bdea9dbf`
  - **After:** [`0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/op.toml#L46)
  - **Summary:** Permissionless DelayedWETH owner update to new Superchain L1PAO
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
    ```bash
    cast storage 0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url sepolia
    # returns 0x000000000000000000000000d363339ee47775888df411a163c586a8bdea9dbf
    cast call 0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c "owner()(address)" --rpc-url sepolia
    # returns 0xd363339eE47775888Df411A163c586a8BdEA9dbf
    ```
  
  ---
  
### [`0xd363339ee47775888df411a163c586a8bdea9dbf`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L46) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 1301
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `32`
  - **After:** `33`
  - **Summary:** nonce
  - **Detail:** Nonce update for the parent multisig.
    
  ---
  
### [`0xeff73e5aa3b9aec32c659aa3e00444d20a84394b`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/unichain.toml#L65) (DisputeGameFactory) - Chain ID: 1301
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0xd363339eE47775888Df411A163c586a8BdEA9dbf`
  - **After:** [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/sepolia/op.toml#L46)
  - **Summary:** DisputeGameFactory owner update to new Superchain L1PAO
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
    ```bash
    cast storage 0xeff73e5aa3b9aec32c659aa3e00444d20a84394b 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url sepolia
    # returns 0x000000000000000000000000d363339ee47775888df411a163c586a8bdea9dbf
    cast call 0xeff73e5aa3b9aec32c659aa3e00444d20a84394b "owner()(address)" --rpc-url sepolia
    # returns 0xd363339eE47775888Df411A163c586a8BdEA9dbf
    ```
  