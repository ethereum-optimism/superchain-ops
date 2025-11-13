// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RevShareContractsUpgrader} from "src/RevShareContractsUpgrader.sol";

/// @notice Deploys the RevShareContractsUpgrader contract.
/// @dev Deployed at https://sepolia.etherscan.io/address/0x9C524DcEa18587e24976A82f05c2065e14DB7B3A
/// @dev Usage:
///      forge script src/script/DeployRevSharesUpgrader.s.sol:DeployRevSharesUpgrader \
///          --rpc-url https://ethereum-sepolia.rpc.subquery.network/public \
///          --broadcast \
///          --verify --private-key $PRIVATE_KEY --verifier custom \
///          --verifier-url 'https://api.etherscan.io/v2/api?chainid=11155111&apikey={$API_KEY}'
/// @dev The libraries were verified from the etherscan's UI as single file using `forge flatten`
contract DeployRevSharesUpgrader is Script {
    /// @notice Deploys the RevShareContractsUpgrader contract
    /// @return upgrader The deployed RevShareContractsUpgrader contract
    function run() public returns (RevShareContractsUpgrader upgrader) {
        vm.startBroadcast();

        // Deploy the RevShareContractsUpgrader
        upgrader = new RevShareContractsUpgrader();

        vm.stopBroadcast();

        // Log the deployed address
        console.log("---");
        console.log("RevShareContractsUpgrader deployed at:", address(upgrader));
        console.log("---");
    }
}
