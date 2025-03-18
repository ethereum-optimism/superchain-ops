# Finance Template Usage

The Finance Template is used for approving or sending ETH or ERC20 tokens from a Safe, and allows multiple actions to be batched into a single transaction.

## Usage

Each Finance Template transaction requires developers to create a new `.toml` file containing the following parameters.

**Template Name** - This specifies which template to use. For the Finance Template, the template name is `FinanceTemplate`.

```templateName = "FinanceTemplate"```

**Operation Type** - This can be of type `approve`, `increaseAllowance`, `decreaseAllowance`, or `transfer`. The operation type specifies the type of operation to perform on the token being transferred. If the token is ETH, the operation type can only be `transfer`.

```operationType = "approve"```

- **Operations** - The operations array specifies the following for each operation:
    - **token** - A string representing the token to transfer. This string corresponds to the token's key in the `addresses` section
    - **amount** - The amount of the token to transfer to the recipient.
    - **target** - The identifier of the receiver for this transfer. This should be the identifier of the recipient address as specified in `addresses`.

**Addresses** - This specifies the addresses of the Gnosis Safe, tokens, and recipients relevant to this template.
 
 - Addresses Object structure:
 
    - **Key** - The identifier of the address. For the Safe that is being used to send tokens, this key is `SafeToSendFrom`. The recipient and token addresses should be assigned names that accurately identify each recipient or token.
    - **Value** - The address corresponding to the identifier's address. For the `SafeToSendFrom` key, this should be the address of the Gnosis Safe that is sending the tokens.

The script can then be run using the following command with the path to the `.toml` file, the network to run the script on, and the block number to fork from filled in:

```bash
forge script src/improvements/template/FinanceTemplate.sol --sig "simulateRun(string)" <path-to-finance-template.toml> --rpc-url <task-network> --fork-block-number <pinned-block-number> -vv
```

This script can be run on testnet using the following command:

```bash
forge script src/improvements/template/FinanceTemplate.sol --sig "simulateRun(string)" test/tasks/mock/configs/TestFinanceTemplate.toml --rpc-url sepolia --fork-block-number 7880546 -vvv
```

## Example

```toml
# this is the file used to determine the network configuration
templateName = "FinanceTemplate"

# Operation is one of:
# approve, increaseAllowance, decreaseAllowance, transfer
operationType = "approve"

# List of operations to perform. In this case, approve 100 TEST tokens to be spent by SecurityCouncil and USER1
operations = [
  {token = "TEST", amount = 100, target = "SecurityCouncil"},
  {token = "TEST", amount = 100, target = "USER1"}
]

[addresses]
# Gnosis Safe that will send tokens
"SafeToSendFrom" = "0xcBC62730b54BFE94173B1182FA56Db1393451d4e"
# Token address
"TEST" = "0xBB4daAC11B4446EE1c6146De1e26ecf1Ab8b3EB6"
# Recipient address
"USER1" = "0x0000000000000000000000000000000000000001"
```

An example finance template can be found [here](../../../test/tasks/mock/configs/TestFinanceTemplate.toml).
