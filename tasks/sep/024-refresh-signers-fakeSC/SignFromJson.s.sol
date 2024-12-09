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
    GnosisSafe securityCouncilSafe =
        GnosisSafe(payable(vm.envAddress("OWNER_SAFE"))); // We take from the "OWNER_SAFE" as this is the "TARGET_SAFE".

    bytes32 livenessGuardSlot =
        0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;
    address livenessGuard =
        address(
            uint160(
                uint256(
                    vm.load(address(securityCouncilSafe), livenessGuardSlot)
                )
            )
        );

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {}

    function getCodeExceptions()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory securityCouncilSafeOwners = securityCouncilSafe
            .getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](
            securityCouncilSafeOwners.length + 3 // 3 is the number of the address we wants to remove here.
        );

        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            shouldHaveCodeExceptions[i] = securityCouncilSafeOwners[i];
        }
        // add the exception of the address that has to be removed.
        shouldHaveCodeExceptions[securityCouncilSafeOwners.length] = address(
            0xad70Ad7Ac30Cee75EB9638D377EACD8DfDfE0C3c
        );

        shouldHaveCodeExceptions[
            securityCouncilSafeOwners.length + 1
        ] = address(0xE09d881A1A13C805ED2c6823f0C7E4443A260f2f);

        shouldHaveCodeExceptions[
            securityCouncilSafeOwners.length + 2
        ] = address(0x78339d822c23D943E4a2d4c3DD5408F66e6D662D);

        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory allowed)
    {
        allowed = new address[](2);
        allowed[0] = address(securityCouncilSafe);
        allowed[1] = livenessGuard;
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
