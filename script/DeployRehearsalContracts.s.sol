// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing necessary contracts and libraries
import {Deployer} from "@eth-optimism-bedrock/scripts/Deployer.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {Script} from "forge-std/Script.sol";

// Importing console utility for logging
import {console2 as console} from "forge-std/console2.sol";

// Contract declaration
contract DeployRehearsalContracts is Deployer {
    // State variables to manage contract ownership and proxy administration
    GnosisSafe owner_safe;
    GnosisSafe council_safe;
    ProxyAdmin proxy_admin;

    /// @notice Overridden to specify the script name for deployment artifacts
    function name() public pure override returns (string memory name_) {
        name_ = "DeployRehearsalContracts";
    }

    // Initial setup function
    function setUp() public override {
        super.setUp();

        // Initializing GnosisSafe contracts for owner and council
        owner_safe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
        council_safe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));

        // Ensuring council_safe is an owner of owner_safe
        require(owner_safe.isOwner(address(council_safe)), "Council safe is not an owner of the owner safe");

        // Logging deployment details
        console.log("Deploying from %s", deployScript);
        console.log("Deployment context: %s", deploymentContext);
    }

    // Main function to orchestrate contract deployment and ownership transfer
    function run() public {
        console.log("Deploying contracts for rehearsal");
        deployProxyAdmin();
        deployL1ERC721BridgeProxy();
        deployOptimismPortalProxy();
        transferProxyAdmin();
        // TODO: Ensure necessary artifacts are saved
        // sync();
    }

    // Function to deploy a ProxyAdmin contract
    function deployProxyAdmin() public broadcast {
        ProxyAdmin admin = new ProxyAdmin({_owner: msg.sender});
        require(admin.owner() == msg.sender, "Deployer is not the owner of the ProxyAdmin");
        save("ProxyAdmin", address(admin));
        console.log("ProxyAdmin deployed at %s", address(admin));
        proxy_admin = admin;
    }

    // Function to deploy a L1ERC721BridgeProxy contract
    function deployL1ERC721BridgeProxy() public broadcast {
        Proxy proxy = new Proxy({_admin: address(proxy_admin)});
        require(EIP1967Helper.getAdmin(address(proxy)) == address(proxy_admin), "ProxyAdmin is not the admin of the proxy");

        address reusedOldL1ERC721Bridge = 0x3268Ed09f76e619331528270B6267D4d2C5Ab5C2;
        proxy_admin.upgrade(payable(proxy), reusedOldL1ERC721Bridge);

        save("L1ERC721BridgeProxy", address(proxy));
        console.log("L1ERC721BridgeProxy deployed at %s", address(proxy));
    }

    // Function to deploy an OptimismPortalProxy contract
    function deployOptimismPortalProxy() public broadcast {
        Proxy proxy = new Proxy({_admin: address(proxy_admin)});
        require(EIP1967Helper.getAdmin(address(proxy)) == address(proxy_admin), "ProxyAdmin is not the admin of the proxy");

        address reusedOldOptimismPortal = 0x28a55488fef40005309e2DA0040DbE9D300a64AB;
        proxy_admin.upgrade(payable(proxy), reusedOldOptimismPortal);

        save("OptimismPortalProxy", address(proxy));
        console.log("OptimismPortalProxy deployed at %s", address(proxy));
    }

    // Function to transfer ownership of ProxyAdmin to owner_safe
    function transferProxyAdmin() public broadcast {
        address new_owner = address(owner_safe);

        if (proxy_admin.owner() != new_owner) {
            proxy_admin.transferOwnership(new_owner);
            console.log("ProxyAdmin ownership transferred to Safe at: %s", new_owner);
        }
    }

    /// @notice Modifier for broadcasting function calls
    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}
