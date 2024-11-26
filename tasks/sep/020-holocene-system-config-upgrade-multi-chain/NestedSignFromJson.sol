// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    string[5] l2ChainIds = [
        "11155420", // op
        "1740", // metal
        "919", // mode
        "999999999", // zora
        "84532" // base
    ];

    address newSystemConfigImplAddress = 0x29d06Ed7105c7552EFD9f29f3e0d250e5df412CD;

    /// @notice Sets up the contract
    function setUp() public {}

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        for (uint256 i = 0; i < l2ChainIds.length; i++) {
            SystemConfig systemConfigProxy =
                SystemConfig(readAddressFromSuperchainRegistry(l2ChainIds[i], "SystemConfigProxy"));
            ProxyAdmin opProxyAdmin = ProxyAdmin(readAddressFromSuperchainRegistry(l2ChainIds[i], "ProxyAdmin"));
            require(opProxyAdmin.getProxyImplementation(systemConfigProxy) == newSystemConfigImplAddress);
            require(systemConfigProxy.Version() == "2.3.0");
        }

        console.log("All assertions passed!");
    }

    function readAddressFromSuperchainRegistry(string memory chainId, string memory contractName)
        internal
        view
        returns (address)
    {
        string memory addressesJson;

        // Read addresses json
        string memory path = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";

        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        return stdJson.readAddress(addressesJson, string.concat("$.", chainId, ".", contractName));
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {}

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // No exceptions are expected in this task, but it must be implemented.
    }
}
