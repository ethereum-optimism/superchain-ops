# Validation

This document can be used to validate the state diff resulting from the execution of setting the recommended protocol version.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe)

The [Foundation Upgrade Safe](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92) is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#system-config-owner) as the current owner of the `SystemConfig`.
The `ProtocolVersions` owner is not mentioned in the docs, but is the same.

To allow simulating the transaction bundle of setting the required versions in a single Tenderly tx, the threshold is overridden to 1.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

## State Changes

More background on `ProtocolVersions` state validation can be found
[here](../../common/protocol-versions.md), including a description of expected event emissions.

### `0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935` (`ProtocolVersions`)

- **Key:** `0x4aaefe95bd84fd3f32700cf3b7566bc944b73138e41958b5785826df2aecace0` <br/>
  **Before:** `0x0000000000000000000000000000000000000008000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000009000000000000000000000000` <br/>
  **Meaning:** This bumps the major version of the *required protocol version* from 8.0.0 to 9.0.0.
  The key is derived from `keccak256('protocolversion.required')-1`. See [../../common/protocol-versions.md](../../common/protocol-versions.md) for more information.

- **Key:** `0xe314dfc40f0025322aacc0ba8ef420b62fb3b702cf01e0cdf3d829117ac2ff1a` <br/>
  **Before:** `0x0000000000000000000000000000000000000008000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000009000000000000000000000000` <br/>
  **Meaning:** This bumps the major version of the *recommended protocol version* from 8.0.0 to 9.0.0.
  The key is derived from `keccak256('protocolversion.recommended')-1`. See [../../common/protocol-versions.md](../../common/protocol-versions.md) for more information.


### Nonce increments

The only other state changes are two nonce increments:

**Key**: 0x0000000000000000000000000000000000000000000000000000000000000005
**Before**: 0x000000000000000000000000000000000000000000000000000000000000000a
**After**: 0x000000000000000000000000000000000000000000000000000000000000000b
**Meaning**: Increment the nonce of the Foundation Upgrade Safe from 10 (0xa) to 11 (0xb). 
- One on the owner on the account that sent the transaction.

