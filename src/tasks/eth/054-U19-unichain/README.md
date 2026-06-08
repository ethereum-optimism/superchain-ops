# 054-U19-unichain

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades Unichain Mainnet (chainId `130`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

Unichain uses a separate ProxyAdminOwner (`0x6d5B183F538ABB8572F5cD17109c617b994D5833`),
independent of the bundled OP-governed upgrade in `053-U19-op-ink-mmz-soneium`.

## Simulation & Signing

```bash
just simulate-stack eth 054-U19-unichain
USE_KEYSTORE=1 just sign-stack eth 054-U19-unichain
```
