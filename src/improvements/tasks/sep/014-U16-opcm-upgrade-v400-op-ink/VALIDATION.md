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
> - Message Hash: `0xc7cfbb96124f4c0e3c0f73ae1aaa55746b7497d5416c4d5c1c792eef6e493c2e`

> ### Nested Safe 2 (Security Council): `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xbfc6bd12af707b0d0f1fed2ea318942bfb4d3fef6d3bf360d3d69d7a1fac54f1`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0xf21c08ee68df610b38634605eee5395ba375c61f84898dbc5e72a8697ed65610`
