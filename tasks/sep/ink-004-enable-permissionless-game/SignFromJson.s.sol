// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Types} from "@eth-optimism-bedrock/scripts/libraries/Types.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

contract SignFromJson is OriginalSignFromJson, SuperchainRegistry {
    using LibString for string;

    constructor() SuperchainRegistry("sepolia", vm.envString("L2_CHAIN_NAME"), "v1.8.0-rc.4") {}

    /// @notice Sets up the contract
    function setUp() public {}

    function checkRespectedGameType() internal view {
        OptimismPortal2 portal = OptimismPortal2(payable(proxies.OptimismPortal));
        require(portal.respectedGameType().raw() == GameTypes.CANNON.raw());
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = proxies.OptimismPortal;
        allowed[1] = vm.envAddress("OWNER_SAFE");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkRespectedGameType();

        console.log("All assertions passed!");
    }
}
