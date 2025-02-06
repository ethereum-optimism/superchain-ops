// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";

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
    using LibString for string;

    DisputeGameFactory constant dgfProxy = DisputeGameFactory(0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1);
    address constant livenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;
    bytes32 constant absolutePrestate = 0x03925193e3e89f87835bbdf3a813f60b2aa818a36bbe71cd5d8fd7e79f5e8afe;
    address constant newMips = 0x69470D6970Cd2A006b84B1d4d70179c892cFCE01;
    address constant oracle = 0x92240135b46fc1142dA181f550aE8f595B858854;
    string constant gameVersion = "1.3.1";
    uint256 constant chainId = 11155420;

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    FaultDisputeGame faultDisputeGame;
    PermissionedDisputeGame permissionedDisputeGame;

    // todo: update to just ink sepolia
    string l2ChainId = "763373"; // ink sepolia;

    // The slot used to store the livenessGuard address in GnosisSafe.
    // See https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/base/GuardManager.sol#L30
    bytes32 livenessGuardSlot = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    address newSystemConfigImplAddress = 0x33b83E4C305c908B2Fc181dDa36e230213058d7d;

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe proxyAdminOwnerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));


    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep/019-fp-holocene-upgrade/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        permissionedDisputeGame = PermissionedDisputeGame(stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl"));
        faultDisputeGame = FaultDisputeGame(stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._impl"));
    }

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
        
        checkProxyAdminproxyAdminOwnerSafe(l2ChainId);
        ISemver systemConfigProxy = ISemver(readAddressFromSuperchainRegistry(l2ChainId, "SystemConfigProxy"));
        ProxyAdmin proxyAdmin = ProxyAdmin(readAddressFromSuperchainRegistry(l2ChainId, "ProxyAdmin"));
        require(
            proxyAdmin.getProxyImplementation(address(systemConfigProxy)) == newSystemConfigImplAddress,
            "SystemConfigProxy implementation not updated"
        );
        require(
            keccak256(abi.encode(systemConfigProxy.version())) == keccak256(abi.encode("2.3.0")),
            "Version not updated"
        );
        
        checkDGFProxyAndGames();
        checkMips();

        console.log("All assertions passed!");
    }

    function checkDGFProxyAndGames() internal view {
        console.log("check dispute game implementations");
        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "dgf-100");
        require(address(permissionedDisputeGame) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-200");

        require(faultDisputeGame.version().eq(gameVersion), "game-100");
        require(permissionedDisputeGame.version().eq(gameVersion), "game-200");

        require(faultDisputeGame.absolutePrestate().raw() == absolutePrestate, "game-300");
        require(permissionedDisputeGame.absolutePrestate().raw() == absolutePrestate, "game-400");

        require(address(faultDisputeGame.vm()) == newMips, "game-500");
        require(address(permissionedDisputeGame.vm()) == newMips, "game-600");

        require(faultDisputeGame.l2ChainId() == chainId, "game-700");
        require(permissionedDisputeGame.l2ChainId() == chainId, "game-800");
    }

    function checkMips() internal view{
        console.log("check MIPS");

        require(newMips.code.length != 0, "MIPS-100");
        vm.assertEq(ISemver(newMips).version(), "1.2.1");
        require(address(MIPS(newMips).oracle()) == oracle, "MIPS-200");
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

        allowed = new address[](7);

        address systemConfigProxy = readAddressFromSuperchainRegistry(l2ChainId, "SystemConfigProxy");
        allowed[0] = systemConfigProxy;
        allowed[1] = address(dgfProxy);
        allowed[2] = address(ownerSafe);
        allowed[3] = address(fndSafe);
        allowed[4] = address(proxyAdminOwnerSafe);
        allowed[5] = address(securityCouncilSafe);
        allowed[6] = livenessGuard;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added, and they are allowed
        // to have code AND to have no code.
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();

        // To make sure we probably handle all signers whether or not they have code, first we count
        // the number of signers that have no code.
        uint256 numberOfSafeSignersWithNoCode;
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                numberOfSafeSignersWithNoCode++;
            }
        }

        // Then we extract those EOA addresses into a dedicated array.
        uint256 trackedSignersWithNoCode;
        address[] memory safeSignersWithNoCode = new address[](numberOfSafeSignersWithNoCode);
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                safeSignersWithNoCode[trackedSignersWithNoCode] = securityCouncilSafeOwners[i];
                trackedSignersWithNoCode++;
            }
        }

        // Here we add the standard (non Safe signer) exceptions.
        address[] memory shouldHaveCodeExceptions = new address[](0 + numberOfSafeSignersWithNoCode);


        // And finally, we append the Safe signer exceptions.
        for (uint256 i = 0; i < safeSignersWithNoCode.length; i++) {
            shouldHaveCodeExceptions[0 + i] = safeSignersWithNoCode[i];
        }

        return shouldHaveCodeExceptions;
    }
}
