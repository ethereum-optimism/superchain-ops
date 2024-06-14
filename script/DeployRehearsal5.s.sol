// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GnosisSafe} from "safe-contracts-v1.3.0/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "safe-contracts-v1.3.0/proxies/GnosisSafeProxyFactory.sol";

import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
// import {DeputyGuardianModule} from "@eth-optimism-bedrock/src/Safe/DeputyGuardianModule.sol";

import {Script} from "forge-std/Script.sol";

import {console2 as console} from "forge-std/console2.sol";

contract DeployRehearsal5 is Script {
    GnosisSafe council_safe;

    /// @notice The name of the script, used to ensure the right deploy artifacts
    ///         are used.
    function name() public pure returns (string memory name_) {
        name_ = "DeployRehearsal5";
    }

    function setUp() public {
        council_safe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));

        console.log("Deploying from %s", name());
        console.log("Deployment context: %s", vm.envOr("DEPLOYMENT_CONTEXT", string("Deployment context not set")));
    }

    function run() public {
        console.log("Deploying contracts for rehearsal");

        deployGuardianSafe();
        deploySuperchainConfig();
        deployDeputyGuardianModule();
    }

    function deployGuardianSafe() public {
        bytes32 salt = keccak256(abi.encode("rehearsal-5", block.number));

        address[] memory owners = new address[](1);
        owners[0] = msg.sender;

        bytes memory initData = abi.encodeCall(
            GnosisSafe.setup, (owners, 1, address(0), hex"", address(0), address(0), 0, payable(address(0)))
        );

        // These are the standard create2 deployed contracts. They should be available on any network we are working on.
        GnosisSafeProxyFactory safeProxyFactory = GnosisSafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
        GnosisSafe safeSingleton = GnosisSafe(payable(0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552));
        address safe = address(safeProxyFactory.createProxyWithNonce(address(safeSingleton), initData, uint256(salt)));

        console.log("New Guardian Safe deployed at %s", address(safe));
    }

    function deploySuperchainConfig() public {}
    function deployDeputyGuardianModule() public {}
}
