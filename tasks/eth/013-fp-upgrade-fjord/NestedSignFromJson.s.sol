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

    // New dispute game implementations
    // See governance proposal for verification - https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236
    FaultDisputeGame constant faultDisputeGame = FaultDisputeGame(0xf691F8A6d908B58C534B624cF16495b491E633BA);
    PermissionedDisputeGame constant permissionedDisputeGame = PermissionedDisputeGame(0xc307e93a7C530a184c98EaDe4545a412b857b62f);

    /// @notice Sets up the dgfProxy 
    function setUp() public {
        string memory addressesJson;
        // Read addresses json
        try vm.readFile(
            string.concat(vm.projectRoot(), "/lib/superchain-registry/superchain/extra/addresses/mainnet/op.json")
        ) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert("Failed to read lib/superchain-registry/superchain/extra/addresses/mainnet/op.json");
        }
        dgfProxy = DisputeGameFactory(stdJson.readAddress(addressesJson, "$.DisputeGameFactoryProxy"));
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        // No code exceptions expected
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxy();
        console.log("All assertions passed!");
    }

    function checkStateDiff(Vm.AccountAccess[] memory accountAccesses) internal view override {
        require(accountAccesses.length > 0, "No account accesses");
        super.checkStateDiff(accountAccesses);

        for (uint256 i; i < accountAccesses.length; i++) {
            Vm.AccountAccess memory accountAccess = accountAccesses[i];

            // Assert that only the expected accounts have been written to.
            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                Vm.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];
                if (storageAccess.isWrite) {
                    address account = storageAccess.account;
                    require(
                        // DisputeGameFactoryProxy is expected to be updated
                        account == address(dgfProxy)
                        // State changes the Safe's are also expected.
                        || account == proxyAdminOwnerSafe || account == securityCouncilSafe
                            || account == foundationUpgradesSafe,
                        "state-100"
                    );
                }
            }
        }
    }

    function checkDGFProxy() internal view {
        console.log("check dispute game implementations");
        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "dgf-100");
        require(address(permissionedDisputeGame) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-200");
    }
}
