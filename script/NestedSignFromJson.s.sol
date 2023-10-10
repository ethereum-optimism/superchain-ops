// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {HelloWorld} from "src/HelloWorld.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/Console.sol";

contract NestedSignFromJson is NestedMultisigBuilder {
    string json;

    function _loadJson(string memory _path) internal {
        console.log("Reading transaction bundle %s", _path);
        try vm.readFile(_path) returns (string memory data) {
            json = data;
        } catch {
            console.log("Error: unable to transaction bundle.");
            return;
        }
    }

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
        // This is a hack.
        uint transaction_count = 9999;
        for(uint i = 0; transaction_count == 9999; i++) {
            try vm.parseJsonAddress(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].to"))) returns (address) {
            } catch {
                transaction_count = i;
            }
        }

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](transaction_count);

        for (uint i = 0; i < transaction_count; i++) {
            calls[i] = IMulticall3.Call3({
                target: stdJson.readAddress(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].to"))),
                allowFailure: false,
                callData: stdJson.readBytes(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].data")))
                });
        }

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return vm.envAddress("OWNER_SAFE");
    }

    function _postCheck() internal view override {}
}
