// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {ProtocolVersionsBump} from "script/verification/ProtocolVersionsBump.s.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

contract SignFromJson is OriginalSignFromJson, ProtocolVersionsBump {
    constructor()
        ProtocolVersionsBump(vm.envAddress("OWNER_SAFE"), ProtoVer(9, 0, 0, 0), ProtoVer(9, 0, 0, 0))
        // In the next line, "op" and ""v1.8.0-rc.4" are not relevant.
        // This is because we only need to read superchain-wide information from the registry.
        // We can use any valid values here.
        SuperchainRegistry("mainnet", "op", "v1.8.0-rc.4")
    {}

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running assertions");
        checkStateDiff(accesses);
        checkProtocolVersions();
        console.log("All assertions passed!");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory) {
        return allowedStorageAccess;
    }

    // No need to override getCodeExceptions() because we do not expect to ever trigger it.
    // We are writing a value which is very unlikely to be interpreted as an address.
}
