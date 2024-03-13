// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Deployer} from "@eth-optimism-bedrock/scripts/Deployer.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {Script} from "forge-std/Script.sol";

import {console2 as console} from "forge-std/console2.sol";

// forge script scripts/Deploy.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL
// forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL
contract DeployRehearsalContracts is Deployer {
    GnosisSafe owner_safe;
    GnosisSafe council_safe;
    ProxyAdmin proxy_admin;

    /// @notice The name of the script, used to ensure the right deploy artifacts
    ///         are used.
    function name() public pure override returns (string memory name_) {
        name_ = "DeployRehearsalContracts";
    }

    function setUp() public override {
        super.setUp();

        owner_safe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
        council_safe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));

        require(owner_safe.isOwner(address(council_safe)));

        console.log("Deploying from %s", deployScript);
        console.log("Deployment context: %s", deploymentContext);
    }

    function run() public {
        console.log("Deploying contracts for rehearsal");
        deployProxyAdmin();
        deployL1ERC721BridgeProxy();
        deployOptimismPortalProxy();
        transferProxyAdmin();
        // todo: ensure that the necessary artifacts are still saved.
        // sync();
    }

    function deployProxyAdmin() public broadcast {
        ProxyAdmin admin = new ProxyAdmin({_owner: msg.sender});
        require(admin.owner() == msg.sender);
        save("ProxyAdmin", address(admin));
        console.log("ProxyAdmin deployed at %s", address(admin));
        proxy_admin = admin;
    }

// Function to deploy the Optimism Portal Proxy
function deployOptimismPortalProxy() public broadcast {
    // Create a new Proxy instance with the specified admin address
    Proxy proxy = new Proxy({_admin: address(proxy_admin)});
    
    // Ensure the admin of the newly created proxy is set correctly
    require(EIP1967Helper.getAdmin(address(proxy)) == address(proxy_admin));

    // Address of the reused old Optimism Portal
    address reusedOldOptimismPortal = 0x28a55488fef40005309e2DA0040DbE9D300a64AB;
    
    // Upgrade the proxy to use the reused old Optimism Portal
    proxy_admin.upgrade(payable(proxy), reusedOldOptimismPortal);

    // Save the address of the deployed proxy
    save("OptimismPortalProxy", address(proxy));
    
    // Log the deployment of the Optimism Portal Proxy
    console.log("OptimismPortalProxy deployed at %s", address(proxy));
}


    function deployOptimismPortalProxy() public broadcast {
        Proxy proxy = new Proxy({_admin: address(proxy_admin)});
        require(EIP1967Helper.getAdmin(address(proxy)) == address(proxy_admin));

        address reusedOldOptimismPortal = 0x28a55488fef40005309e2DA0040DbE9D300a64AB;
        proxy_admin.upgrade(payable(proxy), reusedOldOptimismPortal);

        save("OptimismPortalProxy", address(proxy));
        console.log("OptimismPortalProxy deployed at %s", address(proxy));
    }

    function transferProxyAdmin() public broadcast {
        address new_owner = address(owner_safe);

        if (proxy_admin.owner() != new_owner) {
            proxy_admin.transferOwnership(new_owner);
            console.log("ProxyAdmin ownership transferred to Safe at: %s", new_owner);
        }
    }

    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}
