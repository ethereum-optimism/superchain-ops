# Validation

This document can be used to validate the state diff resulting from the execution of setting the recommended protocol version and the two ownership transfers from the Foundation Operations to the Upgrade Safe (TODO).

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935` (`ProtocolVersions`)

We override the ownership of the PV contract (task#011).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033` <br/>
  **Value:** `0x000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92` <br/>
  **Meaning:** Overrides ownership of PV to the Foundation Upgrades Safe, as if task#011 had been exectued.
      It can also be validated in that tasks's validation description that this change occurs.

### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe)

The [Foundation Upgrade Safe](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92) is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#system-config-owner) as the current owner of the `SystemConfig`.
The `ProtocolVersions` owner is not mentioned in the docs, but is the same.

To allow simulating the transaction bundle of setting the required versions in a single Tenderly tx, the threshold is overridden to 1.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

## State Changes

### `0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935` (`ProtocolVersions`)

- **Key:** `0x4aaefe95bd84fd3f32700cf3b7566bc944b73138e41958b5785826df2aecace0` <br/>
  **Before:** `0x0000000000000000000000000000000000000006000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000007000000000000000000000000` <br/>
  **Meaning:** This bumps the major version of the *required protocol version* from 6.0.0 to 7.0.0.

More background on `ProtocolVersions` state validation can be found
[here](../../common/protocol-versions.md), including a description of expected event emissions.

### Nonce increments

The only other state changes are two nonce increments:

- One on the Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`). If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the owner on the account that sent the transaction.

