// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";

contract SignFromInputJson is MultisigBuilder, JsonTxBuilderBase {
    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        string memory jsonContent = vm.readFile(vm.envOr("INPUT_JSON_PATH", string("input.json")));
        return _buildCallsFromJson(jsonContent);
    }

    // todo: allow passing this as a script argument.
    function _ownerSafe() internal view override returns (address) {
        return vm.envAddress("OWNER_SAFE");
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) internal view virtual override {
        accesses; // Silences compiler warnings.
        simPayload;
        require(false, "SignFromJson::_postCheck not implemented"); // Force user to implement post-check assertions.
    }
}
