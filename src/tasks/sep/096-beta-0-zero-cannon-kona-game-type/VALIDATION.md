# Validation

Task 096 — karst-u19-beta-0 (permissioned correction, part 2/2): zero the CANNON_KONA (game type
8) implementation. Runs after 095.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): `[[konaGameImplConfig]]` impl = `0x0` (disable path),
   gameArgs empty; FDG/PDG are passthroughs.
3. State change: the template `_validate` asserts gameImpls(8)==`0x0` with empty gameArgs;
   gameImpls(0)/gameImpls(1) unchanged.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> beta-0 correction is a **separate signing batch** (grouping B). Hash captured at the assumed
> combined-stack nonce **12**. If beta-0 is signed/executed in its own batch ahead of the alpha
> rollout, the nonce will differ — re-pin and regenerate. Re-verify against your ledger and the
> terminal at signing.
>
> ### Betanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0x4cfa03c2813e41e643b9699a009e2996d3e3e3510ffdb713c70aac4480f8a602`
