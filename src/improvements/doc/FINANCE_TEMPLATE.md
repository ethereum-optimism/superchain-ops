# Finance Template Usage

The Finance Template is used for approving or sending ETH or ERC20 tokens from a Safe, and allows multiple actions to be batched into a single transaction.

Each Finance Template transaction requires developers to create a new `.toml` file containing the following parameters.

See [Single](../SINGLE.md) and [Nested](../NESTED.md) for details on running tasks.

## Example

```toml
# Usage of the Finance Template transaction requires creating a new `.toml` file containing the following parameters.
# This should be done using the `just new task` command

# Template Name - This specifies which template to use. For the Finance Template, the template name is FinanceTemplate.
templateName = "FinanceTemplate"

# Operation Type - This can be of type approve, increaseAllowance, decreaseAllowance, or transfer.
# The operation type specifies the type of operation to perform on the token being transferred.
# If the token is ETH, the operation type can only be transfer.
operationType = "approve"

# Operations - The operations array specifies the following for each operation:
# - token - A string representing the token to transfer. This string corresponds to the token's key in the addresses section
# - amount - The quantity of the token to use in the operation. For transfers this is the amount transferred, 
#   for approvals is the new approval amount, etc. This is specified as a human-readable value, 
#   not using the full amount of decimals for a token. For example, 1 for ETH means 1e18 wei
# - target - A string identifying the account to receive tokens, or to adjust allowance for. 
#   The string corresponds to a key in the addresses section.
operations = [
  {token = "TEST", amount = 100, target = "SecurityCouncil"},
  {token = "TEST", amount = 100, target = "USER1"}
]

# Addresses - This specifies the addresses of the Gnosis Safe, tokens, and recipients relevant to this task.
# Addresses Object structure:
# - Key - The identifier of the address. For the Safe that is being used to send tokens, this key is SafeToSendFrom.
#   The recipient and token addresses should be assigned names that accurately identify each recipient or token.
# - Value - The address corresponding to the identifier's address. For the SafeToSendFrom key,
#   this should be the address of the Gnosis Safe that is sending the tokens.
[addresses]
# Gnosis Safe that will send tokens
"SafeToSendFrom" = "0xcBC62730b54BFE94173B1182FA56Db1393451d4e"
# Token address
"TEST" = "0xBB4daAC11B4446EE1c6146De1e26ecf1Ab8b3EB6"
# Recipient address
"USER1" = "0x0000000000000000000000000000000000000001"
```

An example finance template can be found [here](../template/FinanceTemplate.sol).
