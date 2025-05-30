# 017-1-U16-opcm-upgrade-v400-base-approveHash

Status: [DRAFT]()

## Objective

Performs the approveHash call from the BaseNestedSafe onto Base's L1PAO as a prerequisite for executing task [`017-2-U16-opcm-upgrade-v400-base`](../017-2-U16-opcm-upgrade-v400-base/README.md).

## Simulation & Signing

Simulation commands for each safe:

```bash
cd src/improvements/tasks/sep/017-1-U16-opcm-upgrade-v400-base-approveHash

# For Base
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate base-operations

# For Base Security Council
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate base-council
```

Signing commands for each safe:

```bash
cd src/improvements/tasks/sep/017-1-U16-opcm-upgrade-v400-base-approveHash

# For Base
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just sign base-operations

# For Base Security Council
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just sign base-council
```
