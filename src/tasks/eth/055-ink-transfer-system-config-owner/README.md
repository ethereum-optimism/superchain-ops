# 055-ink-transfer-system-config-owner: Transfer Ink SystemConfig ownership to the FoundationOperationsSafe

Status: DRAFT, NOT READY TO SIGN

## Objective

Transfers ownership of the Ink (mainnet, chainId `57073`) `SystemConfigProxy`
from the current Ink-controlled owner Safe to the `FoundationOperationsSafe`.

- **Target**: `SystemConfigProxy` [`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364)
  ([superchain-registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml))
- **Current owner** (signer): [`0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`](https://etherscan.io/address/0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb)
  — a 3-of-5 Safe controlled by the Gelato team
- **New owner**: [`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A)
  — `FoundationOperationsSafe` (see [`src/addresses.toml`](../../../addresses.toml))

The current owner was verified on-chain:

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "owner()(address)" --rpc-url mainnet
# 0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb
```

The companion testnet task is `sep/101-ink-transfer-system-config-owner`
(same Safe address signs on Sepolia; the two tasks are independent).

> [!CAUTION]
> Ownership transfers are **irreversible** by this Safe once executed: after the
> transfer, only the FoundationOperationsSafe can change SystemConfig parameters
> (gas limit, fee scalars, batcher/sequencer config, …) or transfer ownership
> again. Verify the new owner address against
> [`src/addresses.toml`](../../../addresses.toml) and the
> [superchain-registry](https://github.com/ethereum-optimism/superchain-registry)
> before signing.

## Signers

The current owner Safe is a single-layer 3-of-5 Safe (v1.3.0). Owners
(identical on mainnet and Sepolia):

```
0x691C2EF68e25E620fa6cAdE2728f6aE34F37aAD2
0x6a0A93Cd6d6FB7a36bF6234ef4650Bf9474e7682
0x88De44422E1b1c30bc530c35aEdb9f5aD0e6fD52
0x01a0A7BaAAca31AFB5b770FeFD69CE4917D9c32e
0x547D0F472309e4239b296D01e03bEDc101241a26
```

Note: on mainnet, owner `0x6a0A93Cd6d6FB7a36bF6234ef4650Bf9474e7682` is an
EIP-7702 delegated EOA (its code is the delegation designator
`0xef0100…`). It still signs as a regular EOA owner; the task tooling
recognizes the delegation designator and treats the account as an EOA.

## Simulation & Signing

This is a single-Safe (non-nested) task; see [SINGLE.md](../../../../docs/SINGLE.md).

Simulation:
```bash
cd src/tasks/eth/055-ink-transfer-system-config-owner
SIMULATE_WITHOUT_LEDGER=1 just simulate
```

Signing (requires a connected ledger of one of the Safe owners):
```bash
cd src/tasks/eth/055-ink-transfer-system-config-owner
just sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes,
calldata breakdown, and expected state changes.
