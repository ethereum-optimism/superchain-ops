# Opt-in signer owner-check bypass

## Problems

1. `just sign` and `just sign-stack` call `TaskManager.requireSignerOnSafe` against current onchain state before signing. This blocks a new owner from presigning a later task when an earlier, unexecuted task adds that owner. Tasks `056-fus-rotation-1` and `057-fus-rotation-2` are the immediate example: the owner added by `056` must sign `057` before `056` executes.
2. The owner check is a useful default safety check. Presigning must not weaken or remove it for normal signing.

## Solution

1. Add an opt-in `SKIP_SIGNER_OWNER_CHECK` feature flag to the address overload of `TaskManager.requireSignerOnSafe`. When `Utils.isFeatureEnabled("SKIP_SIGNER_OWNER_CHECK")` returns true, the function prints a `[WARN]` containing the signer and Safe addresses, then returns without reading the Safe owners. Both signing commands already use this function, so the override applies to both without changing `src/justfile`.
2. Preserve the existing owner check whenever the flag is disabled. The flag follows the repository's existing feature-flag behavior and accepts `true` or `1`. Signers enable it for one command:

   ```bash
   SKIP_SIGNER_OWNER_CHECK=1 just sign-stack eth 057-fus-rotation-2
   ```

The override bypasses only the signer owner preflight. It does not change task simulation, Safe transaction construction, hash validation, hardware-wallet signing, or signature verification during execution.

## Work required

1. Update `TaskManager.requireSignerOnSafe(address,address)` with the feature-flag branch and warning.
2. Add a regression test showing that a non-owner still reverts by default and passes when `SKIP_SIGNER_OWNER_CHECK=1`.
3. Document the flag alongside the signing environment variables in `README.md`.

## Non-goals

- Infer ownership after prior stacked tasks. That would require a larger change to the validation flow.
- Restrict the override to specific tasks or signer addresses.
- Store the override in a task's `.env` file. It should remain an explicit per-command choice.
