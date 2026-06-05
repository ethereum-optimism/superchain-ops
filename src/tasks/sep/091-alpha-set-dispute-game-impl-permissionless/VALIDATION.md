# Validation

Task 091 — karst-u19-alpha-1: wire CANNON_KONA (game type 8), set the permissioned fallback
(game type 1) prestate to `0xdead`, leave game type 0 at `0x0`.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): verify the impls + gameArgs.
3. State changes: the template `_validate` asserts gameImpls(8)==`0x2DDA` with the kona gameArgs,
   gameImpls(1)==`0xe1dF` with the `0xdead`-prestate gameArgs, and gameImpls(0) unchanged at `0x0`.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Live Safe nonce is **9** (first task in the single sequential alpha/beta batch). The PAO Safe
> `0x8E851…` is shared across alpha-0/alpha-1/beta-0/beta-1 — re-verify against your ledger and
> the terminal at signing, since the effective nonce depends on stack/batch order.
>
> Regenerated for the pinned nonce **9** and the new kona prestate
> `0x03aabfc1…` (supersedes the earlier nonce-8 / `0x03ff5c52…` capture).
>
> ### Alphanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0xfbeb0b9d9e0c2634d58191ffcb7986c16845acbb18a37fee7e464420a60b71a8`

## Key inputs (see config.toml)

- CANNON_KONA (8): impl `0x2DDA3584b51eF5236f7726Dea5A0FB6B3cA94AeC`, prestate
  `0x03aabfc194f3a1181bf58e5a59ce4287c3153ea283728297e2f253ee423dac94`
  (alpha kona, uploaded to `gs://oplabs-network-data/proofs/kona/cannon/`), bond 0.08 ETH.
- PERMISSIONED_CANNON (1): impl unchanged `0xe1dF…b87e`, prestate → `0xdead…`.
- CANNON (0): unchanged at `0x0`.
