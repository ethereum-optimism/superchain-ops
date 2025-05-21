# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

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
> ### Unichain Upgrade Safe (Chain Governor) (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`)
>
> - Domain Hash:  `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0xaf6de905cc07ab8e11c11b1ff3747f5a8acd86776ef09fd34e44e5601b9a14a0`
>
> ### Optimism Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xb49c66fa395afe0af0b6c7ad4b05dc8e21f66e577f3b0181127556f57e4347fc`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x0489d523fd713500cc9902e04c1fbf4584add97c9a3b02933e2816edf5a377c5`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xde1697d86c8efdb3b8d1e5f93deb075acd0619f75b542fd84886c4592f96ffbf`

## Understanding Task Calldata

The command to encode the calldata is:

First lets define all the contracts that will have their ownership transferred:
- DisputeGameFactoryProxy: [`0x2F12d621a16e2d3285929C9996f478508951dFe4`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L64C30-L64C72)
- Permissioned DelayedWETHProxy: [`0x84B268A4101A8c8e3CcB33004F81eD08202bA124`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L63)
- Permissionless DelayedWETHProxy: `0xc9edb4E340f4E9683B4557bD9db8f9d932177C86` - This address is not references in the superchain registry so we show how to manually retrieve it below.
    ```bash
    # Call the DisputeGameFactoryProxy to get the Permissionless FDG - https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L64C30-L64C72
    cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 0 --rpc-url mainnet
    # returns 0x57a3B42698DC1e4Fb905c9ab970154e178296991
    # Call weth on the Permissionless FDG to get the Permissionless DelayedWETHProxy
    cast call 0x57a3B42698DC1e4Fb905c9ab970154e178296991 "weth()(address)" --rpc-url mainnet
    # returns 0xc9edb4E340f4E9683B4557bD9db8f9d932177C86
    ```
- ProxyAdmin: [`0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L60)

Then we know that we call `transferOwnership` on each of these contracts with the new owner being [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/op.toml#L45C22-L45C64).
Therefore, this calldata should be encoded as:

```bash
cast calldata 'transferOwnership(address)' 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
# returns 0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a
```

Now we can encode the final calldata as:
```
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x2F12d621a16e2d3285929C9996f478508951dFe4, false, 0, 0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a),(0x84B268A4101A8c8e3CcB33004F81eD08202bA124, false, 0, 0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a),(0xc9edb4E340f4E9683B4557bD9db8f9d932177C86, false, 0, 0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a),(0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4, false, 0, 0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a)]"
```


The resulting calldata:
```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000003200000000000000000000000002f12d621a16e2d3285929c9996f478508951dfe40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a0000000000000000000000000000000000000000000000000000000000000000000000000000000084b268a4101a8c8e3ccb33004f81ed08202ba1240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a00000000000000000000000000000000000000000000000000000000000000000000000000000000c9edb4e340f4e9683b4557bd9db8f9d932177c860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a000000000000000000000000000000000000000000000000000000000000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a00000000000000000000000000000000000000000000000000000000
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

### Task State Changes
### [`0x2f12d621a16e2d3285929c9996f478508951dfe4`](https://github.com/ethereum-optimism/superchain-registry/blob/1d642e4ed19a88a5cde3c9eb40143c75822cff98/superchain/configs/mainnet/unichain.toml#L64) (DisputeGameFactory) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** [`0x6d5B183F538ABB8572F5cD17109c617b994D5833`](https://github.com/ethereum-optimism/superchain-registry/blob/1d642e4ed19a88a5cde3c9eb40143c75822cff98/superchain/configs/mainnet/unichain.toml#L45)
  - **After:** [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/7bd81875ca7011527c6b4f5edab8e12d56397863/superchain/configs/mainnet/op.toml#L45)
  - **Summary:** DisputeGameFactory owner update to new Superchain L1PAO
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
  

```bash
cast storage 0x2f12d621a16e2d3285929c9996f478508951dfe4 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url mainnet
# returns 0x0000000000000000000000006d5b183f538abb8572f5cd17109c617b994d5833
cast call 0x2f12d621a16e2d3285929c9996f478508951dfe4 "owner()(address)" --rpc-url mainnet
# returns 0x6d5B183F538ABB8572F5cD17109c617b994D5833
```

---

### [`0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L60)

### (ProxyAdmin) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x6d5B183F538ABB8572F5cD17109c617b994D5833`
  - **After:** [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/1d642e4ed19a88a5cde3c9eb40143c75822cff98/superchain/configs/mainnet/op.toml#L45)
  - **Summary:** ProxyAdmin owner update to new Superchain L1PAO
  

---

### [`0x6d5b183f538abb8572f5cd17109c617b994d5833`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L45) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `32`
  - **After:** `33`
  - **Summary:** nonce
  - **Detail:** Nonce update for the parent multisig.
  

---

### [`0x84b268a4101a8c8e3ccb33004f81ed08202ba124`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L63) (Permissioned DelayedWETH) 

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** [`0x0000000000000000000000006d5b183f538abb8572f5cd17109c617b994d5833`](https://github.com/ethereum-optimism/superchain-registry/blob/1d642e4ed19a88a5cde3c9eb40143c75822cff98/superchain/configs/mainnet/unichain.toml#L45)
  - **After:** [`0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a`](https://github.com/ethereum-optimism/superchain-registry/blob/1d642e4ed19a88a5cde3c9eb40143c75822cff98/superchain/configs/mainnet/op.toml#L45)
  - **Summary:** Permissionless DelayedWETH owner update to new Superchain L1PAO
  - **Detail:** Verify the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:
  

```bash
cast storage 0x84b268a4101a8c8e3ccb33004f81ed08202ba124 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url mainnet
# returns 0x0000000000000000000000006d5b183f538abb8572f5cd17109c617b994d5833
cast call 0x84b268a4101a8c8e3ccb33004f81ed08202ba124 "owner()(address)" --rpc-url mainnet
# returns 0x6d5B183F538ABB8572F5cD17109c617b994D5833  
```

---

### `0xc9edb4e340f4e9683b4557bd9db8f9d932177c86` (Permissionless DelayedWETH) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** [`0x6d5B183F538ABB8572F5cD17109c617b994D5833`](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L45)
  - **After:** [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/1d642e4ed19a88a5cde3c9eb40143c75822cff98/superchain/configs/mainnet/op.toml#L45)
  - **Summary:** Permissionless DelayedWETH owner update to new Superchain L1PAO
  - **Detail:** The superchain registry does not have a link for this contract, so we manually retrieved the address from the DisputeGameFactoryProxy.
  

```bash
# Call the DisputeGameFactoryProxy to get the Permissionless FDG - https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/superchain/configs/mainnet/unichain.toml#L64C30-L64C72
cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 0 --rpc-url mainnet
# returns 0x57a3B42698DC1e4Fb905c9ab970154e178296991
# Call weth on the Permissionless FDG to get the Permissionless DelayedWETHProxy
cast call 0x57a3B42698DC1e4Fb905c9ab970154e178296991 "weth()(address)" --rpc-url mainnet
# returns 0xc9edb4E340f4E9683B4557bD9db8f9d932177C86
```

Also you can check that the slot `0x0000000000000000000000000000000000000000000000000000000000000033` is correct by running the following command and observing that the output is the same as the `Before` value:

```bash
cast storage 0xc9edb4E340f4E9683B4557bD9db8f9d932177C86 0x0000000000000000000000000000000000000000000000000000000000000033 --rpc-url mainnet
# returns 0x0000000000000000000000006d5b183f538abb8572f5cd17109c617b994d5833
cast call 0xc9edb4E340f4E9683B4557bD9db8f9d932177C86 "owner()(address)" --rpc-url mainnet
# returns 0x6d5B183F538ABB8572F5cD17109c617b994D5833
```