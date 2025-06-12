## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Nested Safe 1 (Foundation): `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xf5b4f9b47c6baa410f8e6fe0faded0521d36845765c3fc8d25ae919b2ff66946`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x0da1db92bd8f79154a501a96ee872918190af5c663b495ce17c811748de4af6b`