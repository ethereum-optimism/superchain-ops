// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
contract SignFromJson is OriginalSignFromJson {
    SystemConfig opSystemConfigProxy;

    address opFoundationSystemConfigOwner;

    uint64 initialGasLimit;
    uint64 expectedGasLimit;

    /// @notice Sets up the contract
    function setUp() public {
        opSystemConfigProxy = SystemConfig(readSystemConfigProxyAddress("10"));
        opFoundationSystemConfigOwner = opSystemConfigProxy.owner();

        initialGasLimit = opSystemConfigProxy.gasLimit();
        expectedGasLimit = 60_000_000;
        require(opFoundationSystemConfigOwner == vm.envAddress("OWNER_SAFE"), "SystemConfig owner mismatch");    
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        require(opSystemConfigProxy.gasLimit() != initialGasLimit, "Gas limit not changed");
        require(opSystemConfigProxy.gasLimit() == expectedGasLimit, "Gas limit not set to expected value");
        console.log("All assertions passed!");
    }

    function readSystemConfigProxyAddress(string memory chainId) internal view returns (address) {
        string memory addressesJson;

        // Read addresses json
        string memory path = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";

        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        return stdJson.readAddress(addressesJson, string.concat("$.", chainId, ".SystemConfigProxy"));
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = opFoundationSystemConfigOwner;
        allowed[1] = address(opSystemConfigProxy);
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // No exceptions are expected in this task, but it must be implemented.
    }
}
