# Signer owner-check override implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a Safe owner added by an earlier, unexecuted task presign a later task through an explicit environment-variable override.

**Architecture:** Add the override to `TaskManager.requireSignerOnSafe(address,address)`, which is the shared preflight used by both `just sign` and `just sign-stack`. The function always rejects a zero signer and reads the current Safe owners to validate the target. `SKIP_SIGNER_OWNER_CHECK=true` or `SKIP_SIGNER_OWNER_CHECK=1` prints a warning and skips only owner membership.

**Tech stack:** Solidity 0.8.15, Foundry, `forge-std`, Markdown.

## Global constraints

- The default owner check must remain enabled.
- The override must apply to both `just sign` and `just sign-stack` through their existing shared `TaskManager` call.
- The override must bypass only the signer owner preflight; simulation, transaction construction, hash validation, signing, and execution-time signature validation must remain unchanged.
- The override must still reject a zero signer and a target that does not implement the Safe `getOwners()` interface.
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

Add one test in `test/tasks/TaskManager.t.sol` covering the default and override paths. Use a minimal Safe test contract whose `getOwners()` response excludes the signer. Verify that the default rejects the non-owner, the override permits it, and both paths still reject a zero signer or codeless Safe address. Keep these cases in one test because `vm.setEnv` mutates process-global state.

```solidity
function testRequireSignerOnSafe() public {
    vm.setEnv("SKIP_SIGNER_OWNER_CHECK", "true");

    address[] memory owners = new address[](1);
    owners[0] = address(0x1111);
    SignerOwnerCheckSafe safe = new SignerOwnerCheckSafe(owners);
    TaskManager tm = new TaskManager();
    tm.requireSignerOnSafe(address(0x1234), address(safe));

    vm.setEnv("SKIP_SIGNER_OWNER_CHECK", "");
}
```

- [ ] **Step 2: Run the regression test and verify RED**

Run:

```bash
forge test \
  --match-contract TaskManagerUnitTest \
  --match-test testRequireSignerOnSafe \
  -vv
```

Expected: FAIL because the signer is not in the Safe's owner list.

- [ ] **Step 3: Add the minimal bypass**

Reject a zero signer and read the owners before the feature-flag branch in `TaskManager.requireSignerOnSafe(address,address)`:

```solidity
require(signer != address(0), "TaskManager: signer cannot be the zero address");
address[] memory owners = IGnosisSafe(safe).getOwners();

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

Leave the existing owner-membership `require` after the branch.

- [ ] **Step 4: Run the regression test and verify GREEN**

Run:

```bash
forge test \
  --match-contract TaskManagerUnitTest \
  --match-test testRequireSignerOnSafe \
  -vv
```

Expected: the test passes, prints the skip warning, and observes the expected zero-signer and invalid-Safe reverts.

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
  --match-test testRequireSignerOnSafe \
  -vv
git diff --check
```

Expected: all commands exit `0`. The existing fork-backed `TaskManagerUnitTest` tests will run in GitHub CI with its archive RPC credentials.

- [ ] **Step 7: Commit the implementation**

```bash
git add src/tasks/TaskManager.sol test/tasks/TaskManager.t.sol README.md
git commit -m "feat: allow non-owner task presigning"
```
