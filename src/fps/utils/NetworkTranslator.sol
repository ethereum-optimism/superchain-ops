pragma solidity 0.8.15;

import "src/fps/utils/Constants.sol";

library NetworkTranslator {
    /// TODO think through how to add support for OP devnet.
    /// OP sepolia is supported, but OP devnet is not in this configuration
    function toOpChainId(uint256 chainId) internal pure returns (uint256) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return OP_CHAIN_ID;
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            return OP_SEPOLIA_CHAIN_ID;
        } else {
            revert("no op chainids found");
        }
    }

    function toBaseChainId(uint256 chainId) internal pure returns (uint256) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return BASE_CHAIN_ID;
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            return BASE_SEPOLIA_CHAIN_ID;
        } else {
            revert("no base chainids found");
        }
    }

    function toModeChainId(uint256 chainId) internal pure returns (uint256) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return MODE_CHAIN_ID;
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            return MODE_SEPOLIA_CHAIN_ID;
        } else {
            revert("no mode chainids found");
        }
    }

    function toRaceChainId(uint256 chainId) internal pure returns (uint256) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return RACE_CHAIN_ID;
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            return RACE_SEPOLIA_CHAIN_ID;
        } else {
            revert("no race chainids found");
        }
    }

    function toZoraChainId(uint256 chainId) internal pure returns (uint256) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return ZORA_CHAIN_ID;
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            return ZORA_SEPOLIA_CHAIN_ID;
        } else {
            revert("no zora chainids found");
        }
    }

    /// TODO double check if lyra has a sepolia chainid
    function toLyraChainId(uint256 chainId) internal pure returns (uint256) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return LYRA_CHAIN_ID;
        } else {
            revert("no lyra chainids found");
        }
    }

    function toMetalChainId(uint256 chainId) internal pure returns (uint256) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return METAL_CHAIN_ID;
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            return METAL_SEPOLIA_CHAIN_ID;
        } else {
            revert("no metal chainids found");
        }
    }

    function toBinaryChainId(uint256 chainId) internal pure returns (uint256) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return BINARY_CHAIN_ID;
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            return BINARY_SEPOLIA_CHAIN_ID;
        } else {
            revert("no binary chainids found");
        }
    }
}
