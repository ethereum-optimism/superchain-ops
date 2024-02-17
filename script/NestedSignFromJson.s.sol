// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";

contract NestedSignFromJson is NestedMultisigBuilder, JsonTxBuilderBase {

    function signJson(string memory _path, address _signerSafe) public {
        _loadJson(_path);
        sign(_signerSafe);
    }

    function offchainSim(string memory _path, address _signerSafe, bytes memory _signatures) public {
        Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        // Set threshold to 1
        vm.store(_signerSafe, bytes32(uint256(0x4)), bytes32(uint256(0x1)));
        // Set ownerCount to 1
        vm.store(_signerSafe, bytes32(uint256(0x3)), bytes32(uint256(0x1)));
        // override the owner mapping (slot 2), which requires two key/value pairs: { 0x1: _owner, _owner: 0x1 }
        vm.store(
            _signerSafe,
            bytes32(0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0), // keccak(1 || 2)
            bytes32(uint256(uint160(msg.sender)))
        );
        vm.store(
            _signerSafe,
            keccak256(abi.encode(msg.sender, uint256(2))),
            bytes32(uint256(0x1))
        );

        _loadJson(_path);
        approve(_signerSafe, _signatures);
        // Reset the broadcast bit that was set by approve
        vm.stopBroadcast();
        run();
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

    function _postCheck() internal view override {
        // TODO: invoke the canonical L1 chain assertions
    }
}
