# New Template Creation Guide

This guide explains how to create new Solidity templates for superchain-ops. Templates are the foundation for standardizing and securing task execution across different networks.

## Quick Start

To scaffold a new template:

```bash
cd src/improvements/
just new template <l2taskbase|simpletaskbase|opcmtaskbase>
```

This will create a new Solidity file in `src/improvements/template/` with the basic template structure required.

### Additional steps when creating a new template

Once a new template has been created and tested from the command line as a forge script, it should be tested in the [regression test suite](../../../test/tasks/Regression.t.sol). Follow the existing examples to add a new test case for the template. 

1. Create a new task that uses the new template in the `test/tasks/example/sep` directory.
2. Copy an existing test case inside `Regression.t.sol` that uses a similar template as a starting point.
3. Make sure your new test case uses the new example task that you created in step 1.
4. Make sure to pin the block number in the test case to avoid intermittent failures (you can do this using the `.env` file).
5. Run the regression test suite to ensure the new template passes all tests.

> ⚠️ Note: The CI job `template_regression_tests` will fail if you do not include an example task for your new template. This job only runs on the `main` branch because it is a long running job. It's encouraged that task developers run this locally before pushing changes. You can do this by running `just simulate-all-templates` from `src/improvements/`.

## Existing Templates

Existing templates can be found in the [`src/improvements/template/`](../template) directory. These templates can be used as a reference for creating new templates.

