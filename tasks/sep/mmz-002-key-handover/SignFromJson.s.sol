// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

contract SignFromJson is OriginalSignFromJson {
    ProxyAdmin opProxyAdmin;
    ProxyAdmin metalProxyAdmin;
    ProxyAdmin modeProxyAdmin;
    ProxyAdmin zoraProxyAdmin;

    address opProxyAdminOwner;
    address mmzProxyAdminOwnerBefore;

    /// @notice Sets up the contract
    function setUp() public {
        opProxyAdmin = ProxyAdmin(readProxyAdminAddress("11155420"));
        metalProxyAdmin = ProxyAdmin(readProxyAdminAddress("1740"));
        modeProxyAdmin = ProxyAdmin(readProxyAdminAddress("919"));
        zoraProxyAdmin = ProxyAdmin(readProxyAdminAddress("999999999"));

        opProxyAdminOwner = opProxyAdmin.owner();
        mmzProxyAdminOwnerBefore = metalProxyAdmin.owner();

        require(opProxyAdmin.owner() != metalProxyAdmin.owner());
        require(opProxyAdmin.owner() != modeProxyAdmin.owner());
        require(opProxyAdmin.owner() != zoraProxyAdmin.owner());
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        require(opProxyAdmin.owner() == metalProxyAdmin.owner());
        require(opProxyAdmin.owner() == modeProxyAdmin.owner());
        require(opProxyAdmin.owner() == zoraProxyAdmin.owner());
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
        allowed = new address[](5);
        // The initial ProxyAdminOwner of all chains involved
        allowed[0] = mmzProxyAdminOwnerBefore;
        // The final ProxyAdminOwner of all chains involved
        allowed[1] = opProxyAdminOwner;
        // The ProxyAdmins of all chains involved
        allowed[2] = address(metalProxyAdmin);
        allowed[3] = address(modeProxyAdmin);
        allowed[4] = address(zoraProxyAdmin);
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // No exceptions are expected in this task, but it must be implemented.
    }
}
