# 101-ink-transfer-system-config-owner: Transfer Ink Sepolia SystemConfig ownership to the FoundationOperationsSafe

Status: DRAFT, NOT READY TO SIGN

## Objective

Transfers ownership of the Ink Sepolia (chainId `763373`) `SystemConfigProxy`
from the current Ink-controlled owner Safe to the Sepolia
`FoundationOperationsSafe`.

- **Target**: `SystemConfigProxy` [`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`](https://sepolia.etherscan.io/address/0x05C993e60179f28bF649a2Bb5b00b5F4283bD525)
  ([superchain-registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml))
- **Current owner** (signer): [`0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`](https://sepolia.etherscan.io/address/0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb)
  — a 3-of-5 Safe controlled by the Ink team
- **New owner**: [`0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)
  — Sepolia `FoundationOperationsSafe` (see [`src/addresses.toml`](../../../addresses.toml))

The current owner was verified on-chain:

```bash
cast call 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525 "owner()(address)" --rpc-url sepolia
# 0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb
```

The companion mainnet task is `eth/055-ink-transfer-system-config-owner`
(same Safe address signs on mainnet; the two tasks are independent).

> [!CAUTION]
> Ownership transfers are **irreversible** by this Safe once executed: after the
> transfer, only the FoundationOperationsSafe can change SystemConfig parameters
> or transfer ownership again. Verify the new owner address against
> [`src/addresses.toml`](../../../addresses.toml) and the
> [superchain-registry](https://github.com/ethereum-optimism/superchain-registry)
> before signing.

## Signers

The current owner Safe is a single-layer 3-of-5 Safe (v1.3.0). Owners
(identical on Sepolia and mainnet):

```
0x691C2EF68e25E620fa6cAdE2728f6aE34F37aAD2
0x6a0A93Cd6d6FB7a36bF6234ef4650Bf9474e7682
0x88De44422E1b1c30bc530c35aEdb9f5aD0e6fD52
0x01a0A7BaAAca31AFB5b770FeFD69CE4917D9c32e
0x547D0F472309e4239b296D01e03bEDc101241a26
```

## Simulation & Signing

This is a single-Safe (non-nested) task; see [SINGLE.md](../../../../docs/SINGLE.md).

Simulation:
```bash
cd src/tasks/sep/101-ink-transfer-system-config-owner
SIMULATE_WITHOUT_LEDGER=1 just simulate
```

Signing (requires a connected ledger of one of the Safe owners):
```bash
cd src/tasks/sep/101-ink-transfer-system-config-owner
just sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes,
calldata breakdown, and expected state changes.
