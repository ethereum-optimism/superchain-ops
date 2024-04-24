# Sepolia Proxy Admin Ownership Transfer

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xa7ea1ac70ded1b97b382725b46c6f4b0845e5705e5237a1c13ddfc5c80272ca3)

This runbook is intended to document the act of transferring ownership of the L1 Proxy Admin on
Sepolia, in order to bring it to parity with the current configuration of Mainnet.

This ceremony will be done via the Safe UI rather than the just scripts.

## State Validations

Please ensure that the following changes (and none others) are made to each contract in the system.
The "Before" values are excluded from this list and need not be validated.

## State Overrides

There should also be a single 'State Override' in the Foundation Safe contract
(`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`) to enable the simulation by reducing the threshold to
1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

### `0x189abaaaa82dfc015a588a7dbad6f13b1d3485bc` (`ProxyAdmin`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2` <br/>
  **Meaning:** The owner is changed to a new 2 of 2 Gnosis Safe. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/ProxyAdmin.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/ProxyAdmin.json#L3-L7). The address of the new [FakeProxyAdminOwner Safe](https://app.safe.global/settings/setup?safe=sep:0x1Eb2fFc903729a0F03966B917003800b145F56E2) should be in the slot with left padding to fill the storage slot.

### Validating the FakeProxyAdminOwner Safe:

The safe which assumes ownership of the L1 Proxy Admin should be a 2 of 2 Safe, which is
demonstrably under the control of OP Labs.

This can be validated by:

1. Observing that the signers on the Safe are both themselves Safe contracts:
   - `FakeFoundationSafe`: 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
   - `FakeSecurityCouncil`: 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977
2. Verifying that the Signer sets on each safe match (with the addition of one extra signer on the `FakeSecurityCouncil`)
3. Verifying that the Signers match OP Labs' internal records of account ownership.

### `0xdee57160aafcf04c34c887b5962d0a69676d3c8b` (The FakeFoundationSafe)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x000000000000000000000000000000000000000000000000000000000000000b`<br/>
  **After:** `0x000000000000000000000000000000000000000000000000000000000000000c` <br/>
  **Meaning:** The Safe nonce is updated.
