// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RevShareContractsUpgrader} from "src/RevShareContractsUpgrader.sol";

/// @notice Deploys the RevShareContractsUpgrader contract.
/// @dev Uses CREATE2 for deterministic deployment. If already deployed, returns existing address.
/// @dev Deployed at https://sepolia.etherscan.io/address/0x343312031f639B9e68D7E01535E4c5FAD9c76D42
/// @dev Usage:
///      forge script src/script/DeployRevSharesUpgrader.s.sol:DeployRevSharesUpgrader \
///          --rpc-url https://ethereum-sepolia.rpc.subquery.network/public \
///          --broadcast \
///          --verify --private-key $PRIVATE_KEY --verifier custom \
///          --verifier-url 'https://api.etherscan.io/v2/api?chainid=11155111&apikey={$API_KEY}'
/// @dev The libraries were verified from the etherscan's UI as single file using `forge flatten`
contract DeployRevSharesUpgrader is Script {
    /// @notice Salt used for deterministic deployment
    bytes32 internal constant SALT = keccak256("RevShareContractsUpgrader");

    /// @notice Deploys the RevShareContractsUpgrader contract deterministically using CREATE2
    /// @return upgrader The deployed RevShareContractsUpgrader contract
    function run() public returns (RevShareContractsUpgrader upgrader) {
        // Compute the deterministic address
        bytes32 initCodeHash = keccak256(type(RevShareContractsUpgrader).creationCode);
        address upgraderAddr = vm.computeCreate2Address(SALT, initCodeHash);

        // Check if already deployed (idempotency check)
        if (upgraderAddr.code.length > 0) {
            console.log("---");
            console.log("RevShareContractsUpgrader already deployed at:", upgraderAddr);
            console.log("---");
            return RevShareContractsUpgrader(upgraderAddr);
        }

        // Deploy using CREATE2
        vm.broadcast();
        upgrader = new RevShareContractsUpgrader{salt: SALT}();

        // Log the deployed address
        console.log("---");
        console.log("RevShareContractsUpgrader deployed at:", address(upgrader));
        console.log("---");
    }
}
