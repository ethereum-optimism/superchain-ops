// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// L2 Mainnet Chain Ids
uint256 constant MODE_CHAIN_ID = 34443;
uint256 constant ORDERLY_CHAIN_ID = 291;
uint256 constant RACE_CHAIN_ID = 6805;
uint256 constant ZORA_CHAIN_ID = 7777777;
uint256 constant LYRA_CHAIN_ID = 957;
uint256 constant METAL_CHAIN_ID = 1750;
uint256 constant BINARY_CHAIN_ID = 624;

// L2 Testnet Chain Ids
uint256 constant MODE_SEPOLIA_CHAIN_ID = 919;
uint256 constant BASE_DEVNET_CHAIN_ID = 11763072;
uint256 constant METAL_SEPOLIA_CHAIN_ID = 1740;
uint256 constant RACE_SEPOLIA_CHAIN_ID = 6806;
uint256 constant ZORA_SEPOLIA_CHAIN_ID = 999999999;
uint256 constant OPLABS_DEVNET_CHAIN_ID = 11155421;
uint256 constant BINARY_SEPOLIA_CHAIN_ID = 625;

uint256 constant LOCAL_CHAIN_ID = 31337;

string constant SUPERCHAIN_REGISTRY_PATH = "lib/superchain-registry/superchain/extra/addresses/addresses.json";

address constant MULTICALL3_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;

bytes32 constant SAFE_NONCE_SLOT = bytes32(uint256(5));
