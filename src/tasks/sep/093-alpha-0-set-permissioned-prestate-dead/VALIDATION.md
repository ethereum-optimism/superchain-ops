# Validation

Task 093 — karst-u19-alpha-0 (permissioned): set the PERMISSIONED_CANNON (game type 1) prestate
to `0xdead`. No game type 8; respectedGameType stays 1.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): PDG gameArgs prestate = `0xdead…`, impl unchanged `0xe1dF…`.
3. State change: the template `_validate` asserts gameImpls(1)==`0xe1dF` with the `0xdead`-prestate
   gameArgs; gameImpls(0) and gameImpls(8) remain `0x0`.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Pinned at stack nonce **11** (third in the single sequential alpha/beta batch, after 091/092).
> The PAO Safe `0x8E851…` is shared — re-verify against your ledger and the terminal at signing.
>
> Regenerated for the pinned nonce **11** (after 091/092).
>
> ### Alphanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0xecf6dca8e8ea4ad816cdcdaec4e77f006bbaaa96c4a50d7b546a566b7ab7ee07`
