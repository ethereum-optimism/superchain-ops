// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {LibStateDiffChecker} from "./LibStateDiffChecker.sol";

import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {VmSafe} from "forge-std/Vm.sol";

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

    /// @notice Executes the transaction and records the state diff
    function _executeAndRecordStateDiff(string memory _path)
        internal
        returns (bool, LibStateDiffChecker.StateDiffSpec memory)
    {
        _setLocalSimulationOverrides();
        _loadJson(_path);
        IMulticall3.Call3[] memory calls = _buildCalls();

        vm.startStateDiffRecording();
        bool success = _executeTransaction(_ownerSafe(), calls, prevalidatedSignature(address(this)));
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();
        LibStateDiffChecker.StateDiffSpec memory diff =
            LibStateDiffChecker.extractDiffSpecFromAccountAccesses(accountAccesses);
        return (success, diff);
    }

    function writeDiff(string memory _path) public {
        (bool success, LibStateDiffChecker.StateDiffSpec memory diff) = _executeAndRecordStateDiff(_path);
        success;

        string memory diffPath = string.concat(_getBasePath(_path), "diff.json");
        string memory serializedDiff = LibStateDiffChecker.serializeDiffSpecs(diff);
        vm.writeFile(diffPath, serializedDiff);
    }

    function checkDiff(string memory _path) public {
        // get the expected diff from diff.json
        string memory diffPath = string.concat(_getBasePath(_path), "diff.json");
        string memory specJson = vm.readFile(diffPath);
        LibStateDiffChecker.StateDiffSpec memory expectedDiff = LibStateDiffChecker.parseDiffSpecs(specJson);

        // execute the transaction and get the actual diff
        (bool success, LibStateDiffChecker.StateDiffSpec memory actualDiff) = _executeAndRecordStateDiff(_path);

        // compare the diff with the expected diff
        LibStateDiffChecker.checkStateDiff(expectedDiff, actualDiff);

        if (success) _postCheck();
    }

    // todo: allow passing this as a script argument.
    function _ownerSafe() internal view override(MultisigBuilder, JsonTxBuilderBase) returns (address) {
        return vm.envAddress("OWNER_SAFE");
    }

    function _postCheck() internal view override {}
}
