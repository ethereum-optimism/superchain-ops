# Validation

Task 093 — karst-u19-alpha-1: set `respectedGameType` to 8 (CANNON_KONA). Runs after 092.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): `{chainId = 420100011, gameType = 8}`.
3. State change: the template `_validate` asserts `ASR.respectedGameType() == 8`.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Captured at the assumed stack nonce **9** (second task in the alpha rollout, after 092). The PAO
> Safe `0x8E851…` is shared — re-verify against your ledger and the terminal at signing.
>
> ### Alphanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0xedeaa40480692d2ef87469fba6ff82662595d81fc979d995e0bdcae606c5dd86`
