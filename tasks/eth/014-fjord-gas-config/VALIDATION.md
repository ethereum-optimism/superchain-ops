# Validation

This document can be used to validate the state diff resulting from the execution of setting the recommended protocol version and the two ownership transfers from the Foundation Operations to the Upgrade Safe (TODO).

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (`SystemConfig`)

We override the ownership of the `SystemConfig` contract (task#011).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033` <br/>
  **Value:** `0x000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92` <br/>
  **Meaning:** Overrides ownership of `SystemConfig` to the Foundation Upgrades Safe, as if task#011 had been executed.
      It can also be validated in that tasks's validation description that this change occurs.

### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe)

The [Foundation Upgrade Safe](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92) is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#system-config-owner) as the current owner of the `SystemConfig`.

To allow simulating the transaction bundle of setting the required versions in a single Tenderly tx, the threshold is overridden to 1.
Additionally, the nonce is set to 6 to account for tasks `012` and `013`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000006`
  **Meaning:** Sets the Safe nonce to the hardcoded value of 6. This is the expected value of the Safe nonce at the time of execution. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

## State Changes

### `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (`SystemConfig`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000066` <br/>
  **Before:** `0x010000000000000000000000000000000000000000000000000c5fc500000558` <br/>
  **After:** `0x010000000000000000000000000000000000000000000000000f79c50000146b` <br/>
  **Meaning:** This updates the encoded `scalar` value to hold the new base fee and blob base fee scalars. See next section "Gas Config Update Details" for details.
      The correct slot can be verified with the [storage layout](https://github.com/ethereum-optimism/optimism/blob/31653e5e51c22a239dad1a682b931e696e1539c9/packages/contracts-bedrock/snapshots/storageLayout/SystemConfig.json#L48) (`0x66 = 102`).

More background on `ProtocolVersions` state validation can be found
[here](../../common/protocol-versions.md), including a description of expected event emissions.

The `SystemConfig` also emits a `ConfigUpdate` event, with `updateType` set to `1` and data containing the packed `overhead` and `scalar` values.
The `updateType = 1` value can be verified in the contract source's [enum definition](https://github.com/ethereum-optimism/optimism/blob/31653e5e51c22a239dad1a682b931e696e1539c9/packages/contracts-bedrock/src/L1/SystemConfig.sol#L26).

### Nonce increments

The only other state changes are two nonce increments:

- One on the Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`). If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the owner on the account that sent the transaction.

## Gas Config Update Details

The basefee and blob basefee scalars are updated to
* `L1BaseFeeScalar: 5227`
* `BlobBaseFeeScalar: 1014213`

These values are optimized for sending 5 blobs per transactions on OP Mainnet
and are the result of running [this Fjord chain scalar calculator](https://docs.google.com/spreadsheets/d/1V3CWpeUzXv5Iopw8lBSS8tWoSzyR4PDDwV9cu2kKOrs/edit#gid=186414307)
with the following parameters, which are the default:
* Transactions per day: 500,000
* Comparable Transaction Type : OP Mainnet
* Data Availability Type: Ethereum
* Fault Proofs Enabled: yes
* Max # of Blobs per L1 Transaction: 5
* Target Data Margin: 5%
* Include Output Root Costs in User Fees?: yes

## Transaction creation

Fjord uses the same fee scalar encoding format as Ecotone.

The [`ecotone-scalar`](https://github.com/ethereum-optimism/optimism/tree/develop/op-chain-ops/cmd/ecotone-scalar)
encoding tool was used to determine the correct transaction input (execute in monorepo):
```
go run ./op-chain-ops/cmd/ecotone-scalar --scalar=5227 --blob-scalar=1014213
# base fee scalar     : 5227
# blob base fee scalar: 1014213
# v1 hex encoding  : 0x010000000000000000000000000000000000000000000000000f79c50000146b
# uint value for the 'scalar' parameter in SystemConfigProxy.setGasConfig():
452312848583266388373324160190187140051835877600158453279135543542576845931```
Note the *hex encoding* `0x010000000000000000000000000000000000000000000000000f79c50000146b`.

This encoding follows the [spec change for Ecotone fee scalars](https://github.com/ethereum-optimism/specs/blob/11099e9908bb7bfa640d73b2a3a2349bef9ab7a1/specs/protocol/system_config.md#scalars).
Notably, in version 1 of the scalar encoding format, the `overhead` is set to 0 and the old `scalar` field
now encodes the _base fee scalar_ as well as the _blob base fee scalar_ in a packed format.
The first byte of the `scalar` field denotes the version `0x01`.

The transaction was created in the root directory with

```
just add-transaction tasks/eth/014-fjord-gas-config/input.json 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 'setGasConfig(uint256,uint256)' 0 0x010000000000000000000000000000000000000000000000000f79c50000146b
```

