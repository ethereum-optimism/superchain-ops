// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {HelloWorld} from "src/HelloWorld.sol";
import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/Console.sol";

contract SignFromJson is MultisigBuilder {
    string json;

    function signJson(string memory _path) public {
        console.log("Reading transaction bundle %s", _path);
        try vm.readFile(_path) returns (string memory data) {
            json = data;
        } catch {
            console.log("Error: unable to transaction bundle.");
            return;
        }

        sign();
    }

    function runJson(string memory _path, bytes memory _signatures) public {
        console.log("Reading transaction bundle %s", _path);
        try vm.readFile(_path) returns (string memory data) {
            json = data;
        } catch {
            console.log("Error: unable to transaction bundle.");
            return;
        }

        run(_signatures);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: stdJson.readAddress(json, "$.transactions[0].to"),
            allowFailure: false,
            callData: stdJson.readBytes(json, "$.transactions[0].data")
        });

        return calls;
    }

    // todo: allow passing this as a script argument.
    function _ownerSafe() internal view override returns (address) {
        return vm.envAddress("TOP_LEVEL_SAFE");
    }

    function _postCheck() internal view override {}
}
