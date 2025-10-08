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
> ### Base Operations (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)
>
> - Domain Hash:  `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x6aed739b0f14aeaa148bab6f705a859224f7938c51585d96f1f67b16bb99dd80`
>
> ### Base Council (`0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`)
>
> - Domain Hash:  `0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23`
> - Message Hash: `0x9442df5eb9142f3cafa0d0229a66e9da653dad5bb9b2969189b619acdb1c8671`
>
> ### Base Operations (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`) - Second Approve Hash Transaction
>
> - Domain Hash:  `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0xfe147ec075ed8c65577532418953e3840f9fb26662e7dbb2576a2e778c3387a7`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xccb1531128009f116e4e8608f300128064ddc1585987f9e6441554260f159d8b`

## Task Calldata

Calldata:
```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003bb6437aba031afbf9cb3538fa064161e2bf2d780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a49a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f30339db503776757491b9f3038bf6f1d37b7988a2f75e823fe2656c1352ef2f9100000000000000000000000000000000000000000000000000000000
```