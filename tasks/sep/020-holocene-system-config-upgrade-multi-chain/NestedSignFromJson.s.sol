// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {stdJson} from "forge-std/stdJson.sol";

/// @title ISemver
/// @notice ISemver is a simple contract for ensuring that contracts are
///         versioned using semantic versioning.
interface ISemver {
    /// @notice Getter for the semantic version of the contract. This is not
    ///         meant to be used onchain but instead meant to be used by offchain
    ///         tooling.
    /// @return Semver contract version as a string.
    function version() external view returns (string memory);
}

contract NestedSignFromJson is OriginalNestedSignFromJson {
    string[4] l2ChainIds = [
        "11155420", // op
        "1740", // metal
        "919", // mode
        "999999999" // zora
    ];

    // The slot used to store the livenessGuard address in GnosisSafe.
    // See https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/base/GuardManager.sol#L30
    bytes32 livenessGuardSlot = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    address newSystemConfigImplAddress = 0x33b83E4C305c908B2Fc181dDa36e230213058d7d;

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe proxyAdminOwnerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    /// @notice Sets up the contract
    function setUp() public {}

    function checkProxyAdminproxyAdminOwnerSafe(string memory l2ChainId) internal view {
        ProxyAdmin proxyAdmin = ProxyAdmin(readAddressFromSuperchainRegistry(l2ChainId, "ProxyAdmin"));

        address proxyAdminOwner = proxyAdmin.owner();
        require(proxyAdminOwner == address(proxyAdminOwnerSafe), "checkProxyAdminproxyAdminOwnerSafe-260");

        address[] memory owners = proxyAdminOwnerSafe.getOwners();
        require(owners.length == 2, "checkProxyAdminproxyAdminOwnerSafe-270");
        require(proxyAdminOwnerSafe.isOwner(address(fndSafe)), "checkProxyAdminproxyAdminOwnerSafe-300");
        require(proxyAdminOwnerSafe.isOwner(address(securityCouncilSafe)), "checkProxyAdminproxyAdminOwnerSafe-400");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        for (uint256 i = 0; i < l2ChainIds.length; i++) {
            checkProxyAdminproxyAdminOwnerSafe(l2ChainIds[i]);
            ISemver systemConfigProxy = ISemver(readAddressFromSuperchainRegistry(l2ChainIds[i], "SystemConfigProxy"));
            ProxyAdmin proxyAdmin = ProxyAdmin(readAddressFromSuperchainRegistry(l2ChainIds[i], "ProxyAdmin"));
            require(
                proxyAdmin.getProxyImplementation(address(systemConfigProxy)) == newSystemConfigImplAddress,
                "SystemConfigProxy implementation not updated"
            );
            require(
                keccak256(abi.encode(systemConfigProxy.version())) == keccak256(abi.encode("2.3.0")),
                "Version not updated"
            );
        }

        console.log("All assertions passed!");
    }

    function readAddressFromSuperchainRegistry(string memory chainId, string memory contractName)
        internal
        view
        returns (address)
    {
        string memory addressesJson;

        // Read addresses json
        string memory path = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";

        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        return stdJson.readAddress(addressesJson, string.concat("$.", chainId, ".", contractName));
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        address livenessGuard = address(uint160(uint256(vm.load(address(securityCouncilSafe), livenessGuardSlot))));

        allowed = new address[](9);

        for (uint256 i = 0; i < l2ChainIds.length; i++) {
            address systemConfigProxy = readAddressFromSuperchainRegistry(l2ChainIds[i], "SystemConfigProxy");
            allowed[i] = systemConfigProxy;
        }
        allowed[5] = address(proxyAdminOwnerSafe);
        allowed[6] = address(securityCouncilSafe);
        allowed[7] = address(fndSafe);
        allowed[8] = livenessGuard;
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory exceptions = new address[](0);
        return exceptions;
    }
}
