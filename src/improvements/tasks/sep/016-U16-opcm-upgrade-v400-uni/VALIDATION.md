## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Nested Safe 1 (L1ProxyAdminOwner): `0xd363339eE47775888Df411A163c586a8BdEA9dbf` - This safe is not nested.
>
> - Domain Hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0xae6d9637055732e9bd9fd79d6874d616171381a3eea0516e15165a3fefee1a60` 

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x7c4f49c86766549f938fd0850aa4bf0ca4300116c0b4a6a154e4856147da754c`