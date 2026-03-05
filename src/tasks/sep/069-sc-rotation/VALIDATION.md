# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Single Safe Signer Data
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xa8948caad030cff8a20808f2afae3ee3db641cc89f89f7e80d6a3662766107a9`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the signer rotation.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved plan with no unexpected modifications or side effects.

### Inputs to `safe.swapOwner()`

`safe.swapOwner()` function is called with the address to be removed and the previous owner:

- The address of the new signer: `0xC703d73DB3804662B81b260056d8518Ab54e984E` (Eli)
- The address of the signer to be removed: `0x72e828fdB48Cac259CB60d03222774fBD7e5522C` (Pete)
- The address of the previous signer: `0x2E2E33FEdd27FdeCFC851ae98E45a5ecb76904fE` (this gets calculated by the template)

Thus, the command to encode the calldata is:

```bash
cast calldata 'swapOwner(address, address, address)' "0x2E2E33FEdd27FdeCFC851ae98E45a5ecb76904fE" "0x72e828fdB48Cac259CB60d03222774fBD7e5522C" "0xC703d73DB3804662B81b260056d8518Ab54e984E"
```
