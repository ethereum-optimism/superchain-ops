pragma solidity 0.8.15;

// L1 Chain Ids
uint256 constant ETHEREUM_CHAIN_ID = 1;
uint256 constant SEPOLIA_CHAIN_ID = 11155111;

// L2 Mainnet Chain Ids
uint256 constant BASE_CHAIN_ID = 8453;
uint256 constant OP_CHAIN_ID = 10;
uint256 constant MODE_CHAIN_ID = 34443;
uint256 constant ORDERLY_CHAIN_ID = 291;
uint256 constant RACE_CHAIN_ID = 6805;
uint256 constant ZORA_CHAIN_ID = 7777777;
uint256 constant LYRA_CHAIN_ID = 957;
uint256 constant METAL_CHAIN_ID = 1750;
uint256 constant BINARY_CHAIN_ID = 624;

// L2 Testnet Chain Ids
uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;
uint256 constant OP_SEPOLIA_CHAIN_ID = 11155420;
uint256 constant MODE_SEPOLIA_CHAIN_ID = 919;
uint256 constant BASE_DEVNET_CHAIN_ID = 11763072;
uint256 constant METAL_SEPOLIA_CHAIN_ID = 1740;
uint256 constant RACE_SEPOLIA_CHAIN_ID = 6806;
uint256 constant ZORA_SEPOLIA_CHAIN_ID = 999999999;
uint256 constant OPLABS_DEVNET_CHAIN_ID = 11155421;
uint256 constant BINARY_SEPOLIA_CHAIN_ID = 625;

uint256 constant LOCAL_CHAIN_ID = 31337;

string constant ADDRESSES_PATH = "src/fps/addresses";

string constant SUPERCHAIN_REGISTRY_PATH = "lib/superchain-registry/superchain/extra/addresses/addresses.json";

address constant MULTICALL3_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;

// offset for the nonce variable in Gnosis Safe
bytes32 constant NONCE_OFFSET = 0x0000000000000000000000000000000000000000000000000000000000000005;

bytes32 constant SAFE_NONCE_SLOT = bytes32(uint256(5));

// the amount of modules to fetch from the Gnosis Safe
uint256 constant MODULES_FETCH_AMOUNT = 1_000;

// storage slot for the fallback handler keccak256("fallback_manager.handler.address")
bytes32 constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;
