// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    DisputeGameFactory dgfProxy;

    // Safe contract for this task.
    address immutable proxyAdminOwnerSafe = vm.envAddress("OWNER_SAFE");
    address immutable securityCouncilSafe = vm.envAddress("COUNCIL_SAFE");
    address immutable foundationUpgradesSafe = vm.envAddress("FOUNDATION_SAFE");
    address immutable livenessGuard = 0x24424336F04440b1c28685a38303aC33C9D14a25;

    // New dispute game implementations
    // See governance proposal for verification - https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236
    FaultDisputeGame constant faultDisputeGame = FaultDisputeGame(0xf691F8A6d908B58C534B624cF16495b491E633BA);
    PermissionedDisputeGame constant permissionedDisputeGame = PermissionedDisputeGame(0xc307e93a7C530a184c98EaDe4545a412b857b62f);

    /// @notice Sets up the dgfProxy 
    function setUp() public {
        string memory addressesJson;

        // Read addresses json
        string memory path = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";

        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        dgfProxy = DisputeGameFactory(stdJson.readAddress(addressesJson, string.concat("$.", "10", ".DisputeGameFactoryProxy")));
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        // No code exceptions expected
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](5);
        allowed[0] = address(dgfProxy);
        allowed[1] = proxyAdminOwnerSafe;
        allowed[2] = securityCouncilSafe;
        allowed[3] = foundationUpgradesSafe;
        allowed[4] = livenessGuard;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxy();
        console.log("All assertions passed!");
    }

    function checkDGFProxy() internal view {
        console.log("check dispute game implementations");
        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "dgf-100");
        require(address(permissionedDisputeGame) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-200");
    }
}
