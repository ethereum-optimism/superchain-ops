# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### L1PAO: `@0xd363339eE47775888Df411A163c586a8BdEA9dbf`
>
> - Domain Hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0x6a17c3910e1a5d058620d17e9189d59357c849f9f05a53e9b12f0326ada05414`
## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x1ee1e966e1e8f3e654539cc1acf3fc5109f3cb9dcd91a0b5ab2818f4b751a757`

## Task Calldata

Calldata:
```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003bb6437aba031afbf9cb3538fa064161e2bf2d780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a49a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea403eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc900000000000000000000000000000000000000000000000000000000
```