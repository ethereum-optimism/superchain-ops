// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

contract SignFromJson is OriginalSignFromJson {

    ProxyAdmin opProxyAdmin = ProxyAdmin(0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc);
    ProxyAdmin metalProxyAdmin = ProxyAdmin(0xF7Bc4b3a78C7Dd8bE9B69B3128EEB0D6776Ce18A);
    ProxyAdmin modeProxyAdmin = ProxyAdmin(0xE7413127F29E050Df65ac3FC9335F85bB10091AE);
    ProxyAdmin zoraProxyAdmin = ProxyAdmin(0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2);

    /// @notice Sets up the contract
    function setUp() public view {
        require(opProxyAdmin.owner() != metalProxyAdmin.owner());
        require(opProxyAdmin.owner() != modeProxyAdmin.owner());
        require(opProxyAdmin.owner() != zoraProxyAdmin.owner());
    }


    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory /* accesses */, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");
        require(opProxyAdmin.owner() == metalProxyAdmin.owner());
        require(opProxyAdmin.owner() == modeProxyAdmin.owner());
        require(opProxyAdmin.owner() == zoraProxyAdmin.owner());
        console.log("All assertions passed!");
    }
}
