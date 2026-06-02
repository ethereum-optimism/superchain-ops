# Validation

Task 094 — karst-u19-alpha-0 (permissioned): set the PERMISSIONED_CANNON (game type 1) prestate
to `0xdead`. No game type 8; respectedGameType stays 1.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): PDG gameArgs prestate = `0xdead…`, impl unchanged `0xe1dF…`.
3. State change: the template `_validate` asserts gameImpls(1)==`0xe1dF` with the `0xdead`-prestate
   gameArgs; gameImpls(0) and gameImpls(8) remain `0x0`.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Captured at the assumed stack nonce **10** (third in the alpha rollout, after 092/093). The PAO
> Safe `0x8E851…` is shared — re-verify against your ledger and the terminal at signing.
>
> ### Alphanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0x0b8b86a9ee13c19c2fb4784f07dfcb9c99f5a34a3ff6dce7ed4f7f6b762234f7`
