// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/Console.sol";

contract NestedSignFromJson is NestedMultisigBuilder, JsonTxBuilderBase {

    function signJson(string memory _path, address _signerSafe) public {
        _loadJson(_path);
        sign(_signerSafe);
    }

    function approveJson(string memory _path, address _signerSafe, bytes memory _signatures) public {
        _loadJson(_path);
        approve(_signerSafe, _signatures);
    }

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

    function _postCheck() internal view override {}
}
