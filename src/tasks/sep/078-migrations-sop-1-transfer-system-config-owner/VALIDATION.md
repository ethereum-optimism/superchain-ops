# Validation

This task is signed by the Partner EOA, not a Safe — so there are no domain/message hashes to validate against a ledger UI. Validation here is limited to verifying the calldata that the EOA will sign.

## Pre-execution checks

1. **Verify current owner** (must be the Partner EOA):
   ```bash
   cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "owner()(address)" --rpc-url <SEPOLIA_RPC>
   ```
   Expected: `0x2c9b39d22340b8de532ab5c548e0c773da05a487`

2. **Verify the destination Safe exists and is the correct OPE Admin Safe**. Per the Migration Log, this must be confirmed by ≥3 OP Labs engineers:
   - Address: `0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`
   - Sepolia Etherscan: https://sepolia.etherscan.io/address/0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9

3. **Verify the calldata** matches the expected `transferOwnership(address)` encoding:
   ```bash
   cast calldata "transferOwnership(address)" 0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9
   ```
   Expected output:
   ```
   0xf2fde38b0000000000000000000000008e851f7d8baead95f592847a020cac7a062dafd9
   ```

## Post-execution checks

After the EOA tx confirms:

```bash
cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "owner()(address)" --rpc-url <SEPOLIA_RPC>
```
Expected: `0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`

Record the executed tx hash in the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) execution log section.

## Optional: fork simulation of the template

The `TransferSystemConfigOwnership.sol` template can be exercised against a Sepolia fork to verify the encoded action matches what the EOA will sign:

```bash
cd src/tasks/sep/078-migrations-sop-1-transfer-system-config-owner
# Note: simulation will fail at the Safe-signing step because the current owner is an EOA,
# but the `_build` and `_validate` blocks of the template will produce the same calldata
# you'll be signing with cast.
```
