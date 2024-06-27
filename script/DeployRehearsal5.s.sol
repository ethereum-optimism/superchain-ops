// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GnosisSafe} from "safe-contracts-v1.3.0/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "safe-contracts-v1.3.0/proxies/GnosisSafeProxyFactory.sol";
import {ModuleManager} from "safe-contracts-v1.3.0/base/ModuleManager.sol";
import {OwnerManager} from "safe-contracts-v1.3.0/base/OwnerManager.sol";
import {Enum} from "safe-contracts-v1.3.0/common/Enum.sol";

import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
// import {DeputyGuardianModule} from "@eth-optimism-bedrock/src/Safe/DeputyGuardianModule.sol";

import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";

import {Script} from "forge-std/Script.sol";

import {console2 as console} from "forge-std/console2.sol";

contract DeployRehearsal5 is Script {
    GnosisSafe councilSafe;
    GnosisSafe guardianSafe;
    SuperchainConfig superchainConfigProxy;
    address dummyDeputyGuardianModule = vm.envAddress("DUMMY_DEPUTY_GUARDIAN_MODULE");

    address internal constant SENTINEL_OWNERS = address(0x1);

    /// @notice The name of the script, used to ensure the right deploy artifacts
    ///         are used.
    function name() public pure returns (string memory name_) {
        name_ = "DeployRehearsal5";
    }

    function setUp() public {
        councilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));

        console.log("Deploying from %s", name());
        console.log("Deployment context: %s", vm.envOr("DEPLOYMENT_CONTEXT", string("Deployment context not set")));
    }

    function run() public {
        console.log("Deploying contracts for rehearsal");
        vm.startBroadcast();
        deployGuardianSafe();
        deploySuperchainConfigProxy();
        vm.stopBroadcast();
    }

    function deployGuardianSafe() public {
        address[] memory owners = new address[](1);
        owners[0] = msg.sender;

        bytes memory initData = abi.encodeCall(
            GnosisSafe.setup, (owners, 1, address(0), hex"", address(0), address(0), 0, payable(address(0)))
        );

        // These are the standard create2 deployed contracts. They should be available on any network we are working on.
        GnosisSafeProxyFactory safeProxyFactory = GnosisSafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
        GnosisSafe safeSingleton = GnosisSafe(payable(0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552));
        uint256 salt = uint256(keccak256(abi.encode("rehearsal-5", block.number)));
        guardianSafe =
            GnosisSafe(payable(address(safeProxyFactory.createProxyWithNonce(address(safeSingleton), initData, salt))));

        bytes memory prevalidatedSignature =
            abi.encodePacked(bytes32(uint256(uint160(msg.sender))), bytes32(0), uint8(1));

        // The Guardian Safe must make a call to its own enableModules function
        bytes memory enableModuleData = abi.encodeCall(ModuleManager.enableModule, (dummyDeputyGuardianModule));
        guardianSafe.execTransaction({
            to: address(guardianSafe),
            value: 0,
            data: enableModuleData,
            operation: Enum.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: prevalidatedSignature
        });

        // The Guardian Safe must make a call its own swapOwner function
        bytes memory swapOwnerData =
            abi.encodeCall(OwnerManager.swapOwner, (SENTINEL_OWNERS, msg.sender, address(councilSafe)));
        guardianSafe.execTransaction({
            to: address(guardianSafe),
            value: 0,
            data: swapOwnerData,
            operation: Enum.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: prevalidatedSignature
        });

        console.log("New GuardianSafe deployed at %s", address(guardianSafe));
    }

    function deploySuperchainConfigProxy() public {
        Proxy proxy = new Proxy({_admin: msg.sender});
        address impl = address(new SuperchainConfig());
        proxy.upgradeToAndCall({
            _implementation: impl,
            _data: abi.encodeCall(SuperchainConfig.initialize, (address(guardianSafe), true))
        });
        superchainConfigProxy = SuperchainConfig(address(proxy));
        console.log("New SuperchainConfig Proxy deployed at %s", address(proxy));
    }
}
