// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {ModuleManager} from "safe-contracts/base/ModuleManager.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;
    // Safe contract for this task.
    GnosisSafe foundationUpgradeSafe =
        GnosisSafe(payable(vm.envAddress("OWNER_SAFE"))); // We take from the "OWNER_SAFE" as this is the "TARGET_SAFE".

    address previousowner1 =
        address(0xad70Ad7Ac30Cee75EB9638D377EACD8DfDfE0C3c);
    address previousowner2 =
        address(0xE09d881A1A13C805ED2c6823f0C7E4443A260f2f);

    uint256 numberOwners = foundationUpgradeSafe.getOwners().length;
    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {}

    function getCodeExceptions()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory foundationUpgradeSafeOwners = foundationUpgradeSafe
            .getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](
            foundationUpgradeSafeOwners.length + 2 // 2 is the number of the address we wants to remove here.
        );

        for (uint256 i = 0; i < foundationUpgradeSafeOwners.length; i++) {
            shouldHaveCodeExceptions[i] = foundationUpgradeSafeOwners[i];
        }
        // add the exception of the address that has to be removed.
        shouldHaveCodeExceptions[
            foundationUpgradeSafeOwners.length
        ] = previousowner1;

        shouldHaveCodeExceptions[
            foundationUpgradeSafeOwners.length + 1
        ] = previousowner2;

        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory allowed)
    {
        allowed = new address[](1);
        allowed[0] = address(foundationUpgradeSafe);
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(
        Vm.AccountAccess[] memory accesses,
        Simulation.Payload memory /* simPayload */
    ) internal view override {
        console.log("Running post-deploy assertions");

        address[] memory foundationUpgradeSafeOwners = foundationUpgradeSafe
            .getOwners();

        for (uint256 i = 0; i < foundationUpgradeSafeOwners.length; i++) {
            require(
                foundationUpgradeSafeOwners[i] != previousowner1 &&
                    foundationUpgradeSafeOwners[i] != previousowner2,
                "Previous owners found in the owners list, should have been removed"
            );
        }
        require(
            numberOwners + 1 == foundationUpgradeSafe.getOwners().length,
            "The number of owners should have been increased by 1."
        );
        checkStateDiff(accesses);

        console.log("All assertions passed!");
    }
}
