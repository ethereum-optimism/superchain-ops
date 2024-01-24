# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

Please ensure that the following changes (and none others) are made to each contract in the system.
The "Before" values are excluded from this list and need not be validated.

## State Overrides

There should also be a single 'State Override' in the Foundation Safe contract
(`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`) to enable the simulation by reducing the threshold to
1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

There should also be a single 'State Change' in the Safe Proxy contract
(`0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`), where the Safe nonce is updated.
**Additional Note:** This number may be slightly different if other transactions have recently
been executed. The important thing is that it should change by 1.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000057` <br/>
