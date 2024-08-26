// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PresignPauseFromJson as OriginalPresignPauseFromJson} from "script/PresignPauseFromJson.s.sol";

import {console} from "forge-std/console.sol";

contract PresignPauseFromJson is OriginalPresignPauseFromJson {

    address SuperchainConfig = vm.envAddress("SUPERCHAIN_CONFIG_ADDR");
    address FoundationOperationSafe = vm.envAddress("PRESIGNER_SAFE");

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory allowed)
    {
        allowed = new address[](2);
        allowed[0] = SuperchainConfig; // The storage for the pause will be set to `1`.
        allowed[1] = FoundationOperationSafe; // The nonce is updated in the FoS.
    }
}
