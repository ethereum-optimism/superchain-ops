# Validation

Task 096 — karst-u19-beta-1: bump the CANNON_KONA (game type 8) absolute prestate
`0x0335abee…` → `0x03550cad…`. Permissionless end-state otherwise unchanged. Last task in the
batch.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): `{chainId = 420110024, gameType = 8, prestate = 0x03550cad…}`.
3. State change: the template `_validate` asserts `gameImpls(8)` still `0x2DDA…` and `gameArgs(8)`
   equals the live blob with only the prestate swapped to `0x03550cad…`; impl, vm,
   anchorStateRegistry, delayedWETH, chainId, and init bond are unchanged.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Pinned at the single sequential alpha/beta batch nonce **14** (last task, after 091/092/093/094/095).
> The PAO Safe `0x8E851…` is shared across alpha-0/alpha-1/beta-0/beta-1 — re-verify against your
> ledger and the terminal at signing.
>
> Generated for the pinned nonce **14** (last task, after 091/092/093/094/095).
>
> ### Betanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0xe39f5f63ef1c0b5cb8e37e198f86551c82fe5d9efcd225390b811d22624ad8ab`
