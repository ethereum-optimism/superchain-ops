// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";

contract NestedSignFromJson is NestedMultisigBuilder, JsonTxBuilderBase {
    address globalSignerSafe; // Hack to avoid passing signerSafe as an input to many functions.

    /// @dev Signs the approveHash transaction from the Nested Safe to the System Owner Safe.
    function signJson(string memory _path, address _signerSafe) public {
        _loadJson(_path);
        sign(_signerSafe);
    }

    /// @dev Submits signatures to call approveHash on the System Owner Safe.
    function approveJson(string memory _path, address _signerSafe, bytes memory _signatures) public {
        _loadJson(_path);
        approve(_signerSafe, _signatures);
    }

    /// @dev Executes the transaction from the System Owner Safe.
    function runJson(string memory _path) public {
        _loadJson(_path);
        run();
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        return _buildCallsFromJson();
    }

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
