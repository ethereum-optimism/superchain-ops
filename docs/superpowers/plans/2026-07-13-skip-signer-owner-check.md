# Signer owner-check override implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a Safe owner added by an earlier, unexecuted task presign a later task through an explicit environment-variable override.

**Architecture:** Add the override to `TaskManager.requireSignerOnSafe(address,address)`, which is the shared preflight used by both `just sign` and `just sign-stack`. The default path remains unchanged; `SKIP_SIGNER_OWNER_CHECK=true` or `SKIP_SIGNER_OWNER_CHECK=1` prints a warning and returns before reading current Safe owners.

**Tech stack:** Solidity 0.8.15, Foundry, `forge-std`, Markdown.

## Global constraints

- The default owner check must remain enabled.
- The override must apply to both `just sign` and `just sign-stack` through their existing shared `TaskManager` call.
- The override must bypass only the signer owner preflight; simulation, transaction construction, hash validation, signing, and execution-time signature validation must remain unchanged.
- The bypass must print `[WARN]` with the signer and Safe addresses.
- `SKIP_SIGNER_OWNER_CHECK` must follow `Utils.isFeatureEnabled` semantics and accept `true` or `1`.
- Do not modify `src/justfile`.

---

### Task 1: Add the opt-in preflight bypass

**Files:**
- Modify: `test/tasks/TaskManager.t.sol`
- Modify: `src/tasks/TaskManager.sol`
- Modify: `README.md`

**Interfaces:**
- Consumes: `Utils.isFeatureEnabled(string memory _feature) internal view returns (bool)`.
- Produces: `TaskManager.requireSignerOnSafe(address signer, address safe)` recognizes `SKIP_SIGNER_OWNER_CHECK`; no public signature changes.

- [ ] **Step 1: Write the failing regression test**

Add this test beside the existing `requireSignerOnSafe` tests in `test/tasks/TaskManager.t.sol`. It intentionally uses addresses without deployed code: before the bypass exists, the Safe call fails; after the bypass exists, no onchain state is required.

```solidity
function testRequireSignerOnSafe_PassesIfSignerOwnerCheckIsSkipped() public {
    vm.setEnv("SKIP_SIGNER_OWNER_CHECK", "1");

    TaskManager tm = new TaskManager();
    tm.requireSignerOnSafe(address(0x1234), address(0x5678));

    vm.setEnv("SKIP_SIGNER_OWNER_CHECK", "0");
}
```

- [ ] **Step 2: Run the regression test and verify RED**

Run:

```bash
forge test \
  --match-contract TaskManagerUnitTest \
  --match-test testRequireSignerOnSafe_PassesIfSignerOwnerCheckIsSkipped \
  -vv
```

Expected: FAIL because `requireSignerOnSafe` still calls `getOwners()` on `address(0x5678)`.

- [ ] **Step 3: Add the minimal bypass**

Insert this branch at the start of `TaskManager.requireSignerOnSafe(address,address)` in `src/tasks/TaskManager.sol`:

```solidity
if (Utils.isFeatureEnabled("SKIP_SIGNER_OWNER_CHECK")) {
    console.log(
        string.concat(
            string("[WARN]").yellow().bold(),
            " Skipping the signer owner check for ",
            vm.toString(signer),
            " on Safe ",
            vm.toString(safe),
            " because SKIP_SIGNER_OWNER_CHECK is enabled."
        )
    );
    return;
}
```

Leave the existing `getOwners()` and `require` logic unchanged after the branch.

- [ ] **Step 4: Run the regression test and verify GREEN**

Run:

```bash
forge test \
  --match-contract TaskManagerUnitTest \
  --match-test testRequireSignerOnSafe_PassesIfSignerOwnerCheckIsSkipped \
  -vv
```

Expected: PASS and output containing the skip warning.

- [ ] **Step 5: Document the override**

Add this bullet to the signing environment variables in `README.md`:

```markdown
- `SKIP_SIGNER_OWNER_CHECK` - Set to `true` or `1` to skip the preflight check that requires the signing address to be a current Safe owner. This applies to `just sign` and `just sign-stack`; use it only to presign a task that depends on an earlier owner change.
```

Add this example after the existing `USE_KEYSTORE` example:

````markdown
To presign a task before an earlier owner change executes:

```bash
SKIP_SIGNER_OWNER_CHECK=1 just sign-stack eth 057-fus-rotation-2
```
````

- [ ] **Step 6: Format and verify the change**

Run:

```bash
forge fmt --check
forge test \
  --match-contract TaskManagerUnitTest \
  --match-test testRequireSignerOnSafe_PassesIfSignerOwnerCheckIsSkipped \
  -vv
git diff --check
```

Expected: all commands exit `0`. The existing fork-backed `TaskManagerUnitTest` tests will run in GitHub CI with its archive RPC credentials.

- [ ] **Step 7: Commit the implementation**

```bash
git add src/tasks/TaskManager.sol test/tasks/TaskManager.t.sol README.md
git commit -m "feat: allow non-owner task presigning"
```
