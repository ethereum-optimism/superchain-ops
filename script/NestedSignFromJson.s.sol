// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

contract NestedSignFromJson is NestedMultisigBuilder, JsonTxBuilderBase {
    address globalSignerSafe; // Hack to avoid passing signerSafe as an input to many functions.

    /// @dev Signs the approveHash transaction from the Nested Safe to the System Owner Safe.
    function signJson(string memory _path, address _signerSafe) public {
        _loadJson(_path);
        sign(_signerSafe);
        globalSignerSafe = _signerSafe;
        _postCheckWithSim();
    }

    /// @dev Submits signatures to call approveHash on the System Owner Safe.
    function approveJson(string memory _path, address _signerSafe, bytes memory _signatures) public {
        _loadJson(_path);
        approve(_signerSafe, _signatures);
        globalSignerSafe = _signerSafe;
        _postCheckWithSim();
    }

    /// @dev Executes the transaction from the System Owner Safe.
    function runJson(string memory _path) public {
        _loadJson(_path);
        run();
        // globalSignerSafe = _signerSafe; // TODO how to handle this one?
        // _postCheckWithSim();
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        return _buildCallsFromJson();
    }

    function _ownerSafe() internal view override returns (address) {
        return vm.envAddress("OWNER_SAFE");
    }

    function _postCheck() internal view virtual override {}

    // A thorough postCheck would apply the needed state overrides and run the simulation, then
    // execute those assertions against the resulting state. Using `vm.store` changes state therefore
    // the postCheck methods cannot be `view`, which is why we have this alternate version.
    function _postCheckWithSim() internal virtual {}
}
