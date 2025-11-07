# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

The steps are:
1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Worldchain Sepolia L2 Proxy Admin Owner (Unaliased) (`0x1Eb2fFc903729a0F03966B917003800b145F56E2`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xaaaccdbf1800e8718477851aa8b91ff9477e4ca5d80b2abd848a4e02ad3419a0`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x569e75fc77c1a856f6daaf9e69d8a9566ca34aa47f9133711ce065a571af0cfd`

## Understanding Task Calldata

The transaction initiates a deposit transaction via the OptimismPortal on L1 Sepolia, which will be executed on L2 (Worldchain Sepolia) to transfer the L2 ProxyAdmin ownership to an EOA.

### Decoding the depositTransaction call:
```bash
# The outer multicall to OptimismPortal
cast calldata-decode "depositTransaction(address,uint256,uint64,bool,bytes)" \
   0xe9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000e78a0a96c5d6ae6c606418ed4a9ced378cb030a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041000000000000000000000000f64bc17485f0b4ea5f06a96514182fc4cb56197700000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000
```

Returns:
- `_to`: `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)
- `_value`: `0` (no ETH sent)
- `_gasLimit`: `200000` (gas for L2 execution)
- `_isCreation`: `false` (not a contract creation)
- `_data`: `0xf2fde38b000000000000000000000000e78a0a96c5d6ae6c606418ed4a9ced378cb030a0`

### Decoding the inner transferOwnership call:
```bash
cast calldata-decode "transferOwnership(address)" \
  0xf2fde38b000000000000000000000000e78a0a96c5d6ae6c606418ed4a9ced378cb030a0
```

Returns:
- `newOwnerEOA`: `0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0` (the target EOA)

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../../SINGLE-VALIDATION.md) file.

### Task State Changes

---

### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` ([Worldchain Sepolia ProxyAdminOwner](https://github.com/ethereum-optimism/superchain-registry/blob/1ff0df40c7602761c55ab2cb693614ca0382bd64/superchain/configs/sepolia/worldchain.toml#L44)) - Chain ID: 11155111

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000030`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000031`
  - **Summary:** Safe nonce increment
  - **Detail:** The nonce is incremented by 1 as the safe executes the transaction to initiate the L2 ProxyAdmin ownership transfer.

---

### `0xff6eba109271fe6d4237eeed4bab1dd9a77dd1a4` ([OptimismPortal](https://sepolia.etherscan.io/address/0xff6eba109271fe6d4237eeed4bab1dd9a77dd1a4)) - Chain ID: 11155111

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Decoded Kind:** `struct ResourceMetering.ResourceParams`
  - **Before:** `0x00000000008cc5de0000000000090a010000000000000000000000003b9aca00`
  - **After:** `0x00000000008cc78a0000000000030d400000000000000000000000003b9aca00`
  - **Summary:** Resource metering params update
  - **Detail:** The OptimismPortal's resource metering parameters are updated as part of processing the deposit transaction. This is an expected side effect of calling `depositTransaction`.

## Manual L2 Verification Steps

After the L1 transaction is executed, you must verify that the L2 deposit transaction successfully transfers ownership:

1. **Find the L2 deposit transaction**: Look for a transaction on Worldchain Sepolia from the L1 caller to the L2 ProxyAdmin at `0x4200000000000000000000000000000000000018`.

2. **Verify the OwnershipTransferred event**: Confirm that the event shows:
   - `previousOwner`: `0x2FC3ffc903729a0f03966b917003800B145F67F3` (aliased 2/2 safe)
   - `newOwnerEOA`: `0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0` (target EOA)

3. **Verify final state**: Call `owner()` on the L2 ProxyAdmin to confirm it returns `0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0`.

```bash
# After L2 execution, verify the new owner
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url worldchain-sepolia
# Should return: 0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0
```