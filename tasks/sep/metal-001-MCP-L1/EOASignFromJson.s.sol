// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {EOASignFromJson as OriginalEOASignFromJson} from "script/EOASignFromJson.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract EOASignFromJson is OriginalEOASignFromJson {
    // TODO Implement post Checks.
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload)
        internal
        pure
        override
    {
        accesses;
        simPayload;
        require(false, "EOASignFromJson::_postCheck not implemented");
    }
}
