// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
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

    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload)
        internal
        view
        virtual
        override
    {
        accesses; // Silences compiler warnings.
        simPayload;
        console.log("\x1b[1;33mWARNING:\x1b[0m _postCheck not implemented");
    }
}
