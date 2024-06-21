# Validation

This document can be used to validate the state diff resulting from the execution of setting the recommended protocol version and the two ownership transfers from the Foundation Operations to the Upgrade Safe (TODO).

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (Foundation Operational Safe)

The [Foundation Operations Safe](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A) is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#system-config-owner) as the current owner of the `SystemConfig`.
The `ProtocolVersions` owner is not mentioned in the docs, but is the same.
After execution of this bundle, the ownership will be transferred to the Foundation Upgrade Safe.

To allow simulating the transaction bundle of setting the recommended versions and ownership transfers in a single Tenderly tx, the threshold is overridden to 1.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

## State Changes

### `0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935` (`ProtocolVersions`)

* Key: `0xe314dfc40f0025322aacc0ba8ef420b62fb3b702cf01e0cdf3d829117ac2ff1a`
* Before: `0x0000000000000000000000000000000000000006000000000000000000000000`
* After: `0x0000000000000000000000000000000000000007000000000000000000000000`
* Meaning: This bumps the major version of the *recommended protocol version* from 6 to 7.

* Key: `0x0000000000000000000000000000000000000000000000000000000000000033`
* Before: `0x0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a`
* After: `0x000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92`
* Meaning: Transfers ownership to the Foundation Upgrades Safe. The Tenderly simulation should
    recognize this as a change to the `_owner` value.


More background on `ProtocolVersions` state validation can be found
[here](../common/protocol-versions.md), including a description of expected event emissions.

### `0x229047fed2591dbec1ef1118d64f7af3db9eb290` (`ProtocolVersions`)

* Key: `0x0000000000000000000000000000000000000000000000000000000000000033`
* Before: `0x0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a`
* After: `0x000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92`
* Meaning: Transfers ownership to the Foundation Upgrades Safe. The Tenderly simulation should
    recognize this as a change to the `_owner` value.

The only other state changes are two nonce increments:

- One on the Foundation Operations Safe (`0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`). If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the owner on the account that sent the transaction.

