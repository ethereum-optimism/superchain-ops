// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

contract DeployNestedRehearsal is Script {
    GnosisSafe owner_safe;
    GnosisSafe council_safe;
    ProxyAdmin proxy_admin;

    /// @notice The name of the script, used to ensure the right deploy artifacts are used.
    function name() public pure returns (string memory name_) {
        name_ = "DeployNestedRehearsal";
    }

    function setUp() public {
        owner_safe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
        council_safe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
        require(owner_safe.isOwner(address(council_safe)));
        console.log("Deploying from %s", name());
    }

    function run() public {
        console.log("Deploying contracts for rehearsal");
        deployProxyAdmin();
        deployOptimismPortalProxy();
        transferProxyAdmin();
    }

    function deployProxyAdmin() public broadcast {
        ProxyAdmin admin = new ProxyAdmin({_owner: msg.sender});
        require(admin.owner() == msg.sender);
        console.log("ProxyAdmin deployed at %s", address(admin));
        proxy_admin = admin;
    }

    function deployOptimismPortalProxy() public broadcast {
        Proxy proxy = new Proxy({_admin: address(proxy_admin)});
        require(EIP1967Helper.getAdmin(address(proxy)) == address(proxy_admin));
        address reusedOldOptimismPortal = 0x28a55488fef40005309e2DA0040DbE9D300a64AB;
        proxy_admin.upgrade(payable(proxy), reusedOldOptimismPortal);
        console.log("OptimismPortalProxy deployed at %s", address(proxy));
    }

    function transferProxyAdmin() public broadcast {
        address new_owner = address(owner_safe);

        if (proxy_admin.owner() != new_owner) {
            proxy_admin.transferOwnership(new_owner);
            console.log("ProxyAdmin ownership transferred to ProxyAdminOwner at: %s", new_owner);
        }
    }

    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}
