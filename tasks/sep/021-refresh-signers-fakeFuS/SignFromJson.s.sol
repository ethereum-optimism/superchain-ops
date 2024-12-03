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
    GnosisSafe foundationOperationsSafe =
        GnosisSafe(payable(vm.envAddress("OWNER_SAFE"))); // We take from the "OWNER_SAFE" as this is the "TARGET_SAFE".

    // TODO: Get the livenessGuard from the SC for not hardcoding the address.
    address constant livenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {}

    function getCodeExceptions()
        internal
        view
        override
        returns (address[] memory)
    {
        address[]
            memory foundationOperationsSafeOwners = foundationOperationsSafe
                .getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](
            foundationOperationsSafeOwners.length + 1 // 3 is the number of the address we wants to remove here.
        );

        for (uint256 i = 0; i < foundationOperationsSafeOwners.length; i++) {
            shouldHaveCodeExceptions[i] = foundationOperationsSafeOwners[i];
        }
        // add the exception of the address that has to be removed.
        shouldHaveCodeExceptions[
            foundationOperationsSafeOwners.length
        ] = address(0xad70Ad7Ac30Cee75EB9638D377EACD8DfDfE0C3c);

        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory allowed)
    {
        allowed = new address[](2);
        allowed[0] = address(foundationOperationsSafe);
        allowed[1] = livenessGuard;
        // allowed[2] = address(0xad70Ad7Ac30Cee75EB9638D377EACD8DfDfE0C3c);
        // allowed[3] = address(0xE09d881A1A13C805ED2c6823f0C7E4443A260f2f);
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(
        Vm.AccountAccess[] memory accesses,
        Simulation.Payload memory /* simPayload */
    ) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);

        console.log("All assertions passed!");
    }
}
