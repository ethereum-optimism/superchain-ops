# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x7871d1187A97cbbE40710aC119AA3d412944e4Fe` (The 5 of 7 `ProxyAdmin` owner Safe on L2)

Links:
- [Etherscan](https://optimistic.etherscan.io/address/0x7871d1187A97cbbE40710aC119AA3d412944e4Fe)

Enables the simulation by setting the threshold to 1 (threshold was already 1 for this testnet safe):

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

**Notes:**
- Check the provided links to ensure that the correct contract is described at the correct address.

### `0x4200000000000000000000000000000000000018` (`ProxyAdmin`)

Links:
- [Etherscan](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000018)
- [Optimism Github Repository](https://github.com/ethereum-optimism/optimism/blob/bcdf96abe62da2caaacb0d9571518a7b6c872a37/op-service/predeploys/addresses.go#L23)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000007871d1187a97cbbe40710ac119aa3d412944e4fe` <br/>
  **After:** `0x0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b` <br/>
  **Meaning:** The `_owner` address variable is set to `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/snapshots/storageLayout/ProxyAdmin.json#L4). The current owner of the `ProxyAdmin` contract is `0x7871d1187A97cbbE40710aC119AA3d412944e4Fe`, which is a 5-of-7 Safe owned by the Optimism Foundation. The new `_owner` is `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` which is the aliased L1 Proxy Admin Owner address (unaliased address [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://etherscan.io/address/0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A)) i.e.
   ```
   0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A + 0x1111000000000000000000000000000000001111 = 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
   ```
   You can use [chisel](https://book.getfoundry.sh/chisel/) to verify the aliasing result by invoking the `applyL1ToL2Alias` function.
   ```bash
   applyL1ToL2Alias(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A)
   ```
   You can find a reference to this code here: [`applyL1ToL2Alias`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/vendor/AddressAliasHelper.sol#L28). Paste the `offset` constant into chisel, then paste the `applyL1ToL2Alias` function definition. Finally call the function with the L1 address (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) as an argument and verify it matches the new owner (`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`).

### `0x7871d1187a97cbbe40710ac119aa3d412944e4fe` (Former L2 `ProxyAdmin` Owner (Safe))

Links:
- [Etherscan](https://optimistic.etherscan.io/address/0x7871d1187a97cbbe40710ac119aa3d412944e4fe)
- [Optimism Github Repository](https://github.com/ethereum-optimism/optimism/blob/bcdf96abe62da2caaacb0d9571518a7b6c872a37/op-service/predeploys/addresses.go#L23)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Meaning:** The Safe nonce is updated.

### Fee Transfers

As part of the simulation, you **may** see 'State Changes' in Tenderly for the following addresses:

- `0x4200000000000000000000000000000000000019` - `BaseFeeVault`
- `0x420000000000000000000000000000000000001A` - `L1FeeVault`
- `0x4200000000000000000000000000000000000011` - `SequencerFeeVault`

Tenderly's support for showing these state changes appears experimental, as it's inconsistently shown at the time of writing. Therefore **do not be concerned** if your simulation does or does not show any or all of these 'Fees' state changes from the addresses listed above. If you do see them, just know this is expected behavior.

The only other state change shown will be a nonce increase for the signer account.
This will be your ledger's address if you are signing the transaction, or `0x3041ba32f451f5850c147805f5521ac206421623` if you are simulating without a ledger.
