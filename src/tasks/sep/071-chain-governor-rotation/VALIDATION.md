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
> - Domain Hash: `0x5f0c2af2cc817151aed47fd56cd9431c5ff9f89bbe9491d0af9cd02d1473a8a8`
> - Message Hash: `0x573ede09e95ae5d1cadf005440a8043f4e34219c7e6a891afbc1f89994cad573`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the signer rotation.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved plan with no unexpected modifications or side effects.

### Inputs to `safe.swapOwner()`

`safe.swapOwner()` function is called with the address to be removed and the previous owner:

- The address of the new signer: `0xC703d73DB3804662B81b260056d8518Ab54e984E` (Eli)
- The address of the signer to be removed: `0x72e828fdB48Cac259CB60d03222774fBD7e5522C` (Pete)
- The address of the previous signer: `0x0000000000000000000000000000000000000001` (this gets calculated by the template)

Thus, the command to encode the calldata is:

```bash
cast calldata 'swapOwner(address, address, address)' "0x0000000000000000000000000000000000000001" "0x72e828fdB48Cac259CB60d03222774fBD7e5522C" "0xC703d73DB3804662B81b260056d8518Ab54e984E"
```
