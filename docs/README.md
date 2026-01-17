# Documentation

This directory contains documentation for the superchain-ops task system.

## Key Concepts

### Validation Files

Every task requires a `VALIDATION.md` file so signers know they are signing the right thing.

When signing a transaction with a hardware wallet, signers see only cryptographic hashes - not human-readable details about what the transaction does. The validation file bridges this gap by providing:

- **Expected domain and message hashes** - Signers verify these match their hardware wallet display before approving
- **Detailed breakdown of the transaction** - What contracts are called, what parameters are passed
- **Expected state changes** - What onchain state will change after execution

This ensures signers can independently verify they are approving the intended operation, not a malicious transaction.

## Index

| Document | Description |
|----------|-------------|
| [NEW_TASK_GUIDE.md](NEW_TASK_GUIDE.md) | How to create a new task using existing templates |
| [NEW_TEMPLATE_GUIDE.md](NEW_TEMPLATE_GUIDE.md) | How to create a new template for tasks |
| [SINGLE.md](SINGLE.md) | Single safe execution workflow |
| [NESTED.md](NESTED.md) | Nested safe execution workflow |
| [SINGLE-VALIDATION.md](SINGLE-VALIDATION.md) | Validation patterns for single safe operations |
| [NESTED-VALIDATION.md](NESTED-VALIDATION.md) | Validation patterns for nested safe operations |
| [simulate-l2-deposit-transactions.md](simulate-l2-deposit-transactions.md) | Simulating L2 deposit transactions with integration tests |
| [simulate-l2-ownership-transfer.md](simulate-l2-ownership-transfer.md) | Simulating L2 ownership transfers via Tenderly |
