# 054-U19-unichain

Status: [READY TO SIGN]()

## Objective

Upgrades Unichain Mainnet (chainId `130`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

Unichain uses a separate ProxyAdminOwner (`0x6d5B183F538ABB8572F5cD17109c617b994D5833`),
independent of the bundled OP-governed upgrade in `053-U19-op-ink-mmz-soneium`.

## Simulation & Signing

This task is signed by Unichain's ProxyAdminOwner, a nested 3-of-3 of the
Foundation Upgrade Safe, the Security Council, and the Unichain Chain Governor
Safe. Run the commands once for the safe you sign for, replacing
`<foundation|council|chain-governor>` with `foundation`, `council`, or
`chain-governor`.

`SKIP_DECODE_AND_PRINT=1` skips the slow human-readable state-diff printout
without changing the domain/message hashes you verify or the Tenderly link. It
is set on the sign command below; you can also prefix `simulate-stack` with it
for a faster run (review state changes via the Tenderly link instead).

### For Signers

```bash
# Change directory to the task
cd src/tasks/eth/054-U19-unichain

# Simulate
just simulate-stack eth 054-U19-unichain <foundation|council|chain-governor>

# Sign
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 054-U19-unichain <foundation|council|chain-governor>

# Add USE_KEYSTORE=1 before the command if you are signing with a local keystore
# instead of a connected Ledger, e.g.
#   USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack eth 054-U19-unichain <foundation|council|chain-governor>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the task
cd src/tasks/eth/054-U19-unichain

# Approve once per safe, passing that safe's collected signatures
SIGNATURES=0x... just approve <foundation|council|chain-governor>

# Execute once all three safes have approved
just execute

# Add USE_KEYSTORE=1 before the command if you are using a local keystore
# instead of a connected Ledger.
```
