# Rehearsal - L1→L2 No‑op via OptimismPortal

## Objective
Dry-run the nested SC ceremony to send a no‑op L2 call through the L1 OptimismPortal.

## Steps (nested)
1) Update addresses in `config.toml`.
2) Simulate from the signer’s Safe:
```sh
just --dotenv-path $(pwd)/.env simulate council
# or foundation / chain-governor
```
3) Validate
- Tenderly state diff has no unintended changes
- op‑txverify shows: Safe → OptimismPortal.depositTransaction → decoded inner L2 call
- Extract domain/message hashes and match Ledger
4) Sign
```sh
just --dotenv-path $(pwd)/.env sign council
```
5) Facilitator approve/execute per `NESTED.md`.

## Notes
- `gasLimit` must be explicit. `value` defaults to 0.
- Use a semantic no‑op inner calldata (e.g. upgradeTo current impl) or read‑only target for rehearsal.


