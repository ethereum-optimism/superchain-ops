# Validation

Task 092 — karst-u19-alpha-1: set `respectedGameType` to 8 (CANNON_KONA). Runs after 091.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): `{chainId = 420100011, gameType = 8}`.
3. State change: the template `_validate` asserts `ASR.respectedGameType() == 8`.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Pinned at stack nonce **10** (second task in the single sequential alpha/beta batch, after 091
> at nonce 9). The PAO Safe `0x8E851…` is shared — re-verify against your ledger and the terminal
> at signing.
>
> Regenerated for the pinned nonce **10** (after 091 at nonce 9).
>
> ### Alphanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0xc5d7a647963155134cad200f32eaad7b65622808a7dbc5203844987fc52efadd`
