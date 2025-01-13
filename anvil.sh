#!/bin/bash
  ownerSafe="0x847B5c174615B1B7fDF770882256e2D3E95b9D92"
  rpcUrl="http://localhost:8545"
  echo ${ownersafe}
  echo ${rpcUrl}
  echo "============ OVERRIDE SAFE SETTINGS ============"
  echo "1. Set the threshold to 1."
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${rpcUrl}
  
  echo "2.set the owner count to 1."
  ## 2. Set the owner count to 1.
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000003 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${rpcUrl}

  echo "3.Insert the address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 as the sole owner of the safe."
  ## 3. Set the 0xf39 address to the sole signer of the safe.
  # cast keccak 1 || 2 => 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 expected owner mapping: {0x1 -> 0xf39..., 0xf39 -> 0x1}
  cast rpc anvil_setStorageAt ${ownerSafe} 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 0x000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${rpcUrl}
  ## 4. Set the owner (abi.encode(owner, uint256(2)))-> to sentinel_address (0x1).
  echo "4.Close the mapping of the owners to the sentinel address."
  cast rpc anvil_setStorageAt ${ownerSafe} 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1  0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${rpcUrl}

  cast call 0x847B5C174615B1B7FDF770882256E2D3E95B9D92  "getOwners()" --rpc-url http://localhost:8545
  echo "================================================"

