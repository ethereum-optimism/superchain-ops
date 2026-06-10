# 098-osaki-l2pao-transfer: Transfer L2 ProxyAdmin Owner for Osaki Sepolia

Status: [READY TO SIGN]()

## Objective

Transfer the L2 ProxyAdmin Owner of Osaki Sepolia (chainId 9111973) from the
current value (`0x2FC3ffc903729a0f03966b917003800B145F67F3` — the alias of the
standard Sepolia L1PAO Safe) to the L1-to-L2 alias of the new L1 owner Safe
`0xFB0F8937A0d6999C67E8a01310eBf7fe1859205F`.

The transfer is executed via a deposit transaction through the L1
OptimismPortal (`0x7218b76ad6c329e731aa3213c65fb05634691238`), which is then
forwarded to the L2 ProxyAdmin predeploy
(`0x4200000000000000000000000000000000000018`). The `TransferL2PAOFromL1`
template aliases the provided unaliased owner automatically; the resulting
aliased owner that lands on L2 is:

```
0x0C208937a0D6999c67E8A01310ebF7fE18593170
```

This task is stacked after task `097-osaki-l1-ownership-transfers`. The
template asserts that the L1 ProxyAdmin owner already equals the unaliased
`newOwnerToAlias`, so task 097 must be executed first. A `stateOverrides`
entry in `config.toml` pre-applies the L1 transfer so this task can also be
simulated standalone.

To gain additional assurance that the corresponding L2 deposit transaction
works as expected, follow
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md)
and record the result in `VALIDATION.md`.

## Simulation & Signing

The L1PAO Safe is a 2-of-2 nested Safe (FoundationUpgradeSafe + SecurityCouncil),
so simulation and signing are run once per child Safe.

Simulation commands for each safe:
```bash
cd src/tasks/sep/098-osaki-l2pao-transfer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <foundation|council>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/098-osaki-l2pao-transfer
just --dotenv-path $(pwd)/.env sign <foundation|council>
```

## Manual Post-Execution Checks

1. Find the L2 deposit transaction on Osaki Sepolia from the L1 caller (the
   standard Sepolia L1PAO Safe aliased to L2 as
   `0x2FC3ffc903729a0f03966b917003800B145F67F3`) to the L2 ProxyAdmin predeploy
   `0x4200000000000000000000000000000000000018`.
2. Verify the `OwnershipTransferred` event:
   - `previousOwner`: `0x2FC3ffc903729a0f03966b917003800B145F67F3`
   - `newOwner`:      `0x0C208937a0D6999c67E8A01310ebF7fE18593170`
3. Confirm the final state:
   ```bash
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url <osaki-sepolia-rpc>
   # Expected: 0x0C208937a0D6999c67E8A01310ebF7fE18593170
   ```
