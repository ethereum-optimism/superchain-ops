#!/usr/bin/env bash
set -euo pipefail

OPTIMISM_PORTAL_PROXY=0x5d66c1782664115999c47c9fa5cd031f495d3e4f
GUARDIAN=0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2
CHAINID=57073
#DGM=0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B

# Generate JSON
cat << EOF
{
  "version": "1.0",
  "chainId": "$CHAINID",
  "createdAt": $(date +%s%3N),
  "meta": {
    "name": "Deputy Guardian - Set respected game type to permissionless cannon",
    "description": ""
  },
  "transactions": [
    {
      "to": "$GUARDIAN",
      "value": "0",
      "data": "0x6a76120200000000000000000000000009f7150d8c019bef34450d6920f6b3608cefdaf20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000000247fc485040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041000000000000000000000000c2819dc788505aac350142a7a707bf9d03e3bd0300000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000",
      "contractMethod": {
         "inputs": [
              { "internalType": "address", "name": "to", "type": "address" },
              { "internalType": "uint256", "name": "value", "type": "uint256" },
              { "internalType": "bytes", "name": "data", "type": "bytes" },
              { "internalType": "enum Enum.Operation", "name": "operation", "type": "uint8" },
              { "internalType": "uint256", "name": "safeTxGas", "type": "uint256" },
              { "internalType": "uint256", "name": "baseGas", "type": "uint256" },
              { "internalType": "uint256", "name": "gasPrice", "type": "uint256" },
              { "internalType": "address", "name": "gasToken", "type": "address" },
              { "internalType": "address payable", "name": "refundReceiver", "type": "address" },
              { "internalType": "bytes", "name": "signatures", "type": "bytes" }
        ],
        "name": "execTransaction",
        "payable": true
      },
      "contractInputsValues": {
        "to": "$OPTIMISM_PORTAL_PROXY",
        "value": "0",
        "data": "0x7fc485040000000000000000000000000000000000000000000000000000000000000000",
        "operation": "0",
        "safeTxGas": "0",
        "baseGas": "0",
        "gasPrice": "0",
        "gasToken": "0x0000000000000000000000000000000000000000",
        "refundReceiver": "0x0000000000000000000000000000000000000000",
        "signatures": "0x000000000000000000000000c2819dc788505aac350142a7a707bf9d03e3bd03000000000000000000000000000000000000000000000000000000000000000001"
      }
    }
  ]
}
EOF