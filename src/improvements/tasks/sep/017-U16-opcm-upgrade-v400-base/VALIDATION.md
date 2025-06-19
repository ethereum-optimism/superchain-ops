## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Nested Safe 1: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0xa2ee651b40adf1e6777d8212dad3f25e3f33ca60884538433b5641941dc05697`
>
> ### Nested Safe 2: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`
>
> - Domain Hash: `0x1d3f2566fd7b1bf017258b03d4d4d435d326d9cb051d5b7993d7c65e7ec78d0e`
> - Message Hash: `0x7133b38df611165edee8669b9a974d749d004e814b66511719e4ab5c9cf7218e`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x1a82465ee90d8ea2776a61797d9c134cac943e96f3314cf90beb2e3cd6cb3c84`
