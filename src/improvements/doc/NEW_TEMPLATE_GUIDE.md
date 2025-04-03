# New Template Creation Guide

This guide explains how to create new Solidity templates for the superchain task system. Templates are the foundation for standardizing and securing task execution across different networks.

## Quick Start

To scaffold a new template:

```bash
cd src/improvements/
just new template <l2taskbase|simplebase|opcmbasetask>
```

This will create a new Solidity file in `src/improvements/template/` with the basic template structure required.

## Existing Templates

Existing templates can be found in the [`src/improvements/template/`](../template) directory. These templates can be used as a reference for creating new templates.

## Testing

Once a new template has been created and tested from the command line as a forge script, it should be tested in the [regression test suite](../../../test/tasks/Regression.t.sol). Follow the existing examples to add a new test case for the template. 

1. Import the new template into the regression test suite.
2. Add a new test case that deploys the template and tests its functionality. Make sure to lock the block number and network in the test case to avoid intermittent failures.
3. Run the regression test suite to ensure the new template passes all tests.
