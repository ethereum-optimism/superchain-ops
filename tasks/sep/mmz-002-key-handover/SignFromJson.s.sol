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

    /// @notice Sets up the contract
    function setUp() public {
        opProxyAdmin = ProxyAdmin(readProxyAdminAddress("11155420"));
        metalProxyAdmin = ProxyAdmin(readProxyAdminAddress("1740"));
        modeProxyAdmin = ProxyAdmin(readProxyAdminAddress("919"));
        zoraProxyAdmin = ProxyAdmin(readProxyAdminAddress("999999999"));
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
    function checkStateDiff(Vm.AccountAccess[] memory accountAccesses) internal view override {
        super.checkStateDiff(accountAccesses);

        address metalProxyAdminOwner = metalProxyAdmin.owner();
        address modeProxyAdminOwner = modeProxyAdmin.owner();
        address zoraProxyAdminOwner = zoraProxyAdmin.owner();
        address opProxyAdminOwner = 0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD;

        for (uint256 i; i < accountAccesses.length; i++) {
            Vm.AccountAccess memory accountAccess = accountAccesses[i];

            // Assert that only the expected accounts have been written to.
            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                Vm.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];
                if (storageAccess.isWrite) {
                    address account = storageAccess.account;
                    require(
                        // We set the guardian slot on the Superchain Config.
                        account == metalProxyAdminOwner || account == modeProxyAdminOwner
                            || account == zoraProxyAdminOwner
                            || account == opProxyAdminOwner,
                        "state-100"
                    );
                }
            }
        }
    }
}
