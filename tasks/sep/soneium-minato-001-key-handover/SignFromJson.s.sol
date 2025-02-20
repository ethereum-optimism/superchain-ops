// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

contract SignFromJson is OriginalSignFromJson {
    ProxyAdmin opProxyAdmin;
    ProxyAdmin minatoProxyAdmin;

    address opProxyAdminOwner;
    address minatoProxyAdminOwnerBefore;

    /// @notice Sets up the contract
    function setUp() public {
        opProxyAdmin = ProxyAdmin(readProxyAdminAddress("11155420"));
        minatoProxyAdmin = ProxyAdmin(readProxyAdminAddress("1946"));

        opProxyAdminOwner = opProxyAdmin.owner();
        minatoProxyAdminOwnerBefore = minatoProxyAdmin.owner();

        require(opProxyAdmin.owner() != minatoProxyAdmin.owner());
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions for Minato");
        checkStateDiff(accesses);
        require(opProxyAdmin.owner() == minatoProxyAdmin.owner());
        console.log("All assertions passed!");
    }

    function readProxyAdminAddress(string memory chainId) internal view returns (address) {
        string memory addressesJson;

        // Read addresses json
        string memory path = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";

        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        return stdJson.readAddress(addressesJson, string.concat("$.", chainId, ".ProxyAdmin"));
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](3);
        // The initial ProxyAdminOwner of Minato
        allowed[0] = minatoProxyAdminOwnerBefore;
        // The final ProxyAdminOwner of all chains involved
        allowed[1] = opProxyAdminOwner;
        // The ProxyAdmins of Minato
        allowed[2] = address(minatoProxyAdmin);
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // No exceptions are expected in this task, but it must be implemented.
    }
}
