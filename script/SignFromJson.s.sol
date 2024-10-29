// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";

contract SignFromJson is MultisigBuilder, JsonTxBuilderBase {
    function signJson(string memory _path) public {
        _loadJson(_path);
        sign();
    }

    function runJson(string memory _path, bytes memory _signatures) public {
        _loadJson(_path);
        run(_signatures);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        return _buildCallsFromJson();
    }

    // todo: allow passing this as a script argument.
    function _ownerSafe() internal view override returns (address) {
        return vm.envAddress("OWNER_SAFE");
    }

    function _postSign(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload)
        internal
        virtual
        override
    {
        _postCheck(accesses, simPayload);
    }

    function _postRun(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload)
        internal
        virtual
        override
    {
        _postCheck(accesses, simPayload);
    }

    function _postCheck() internal virtual override {}

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {
        accesses; // Silences compiler warnings.
        simPayload;
        require(false, "_postCheck not implemented");
    }
}
