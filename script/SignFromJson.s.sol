// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {ChainAssertions, Types, DeployConfig} from "@eth-optimism-bedrock/scripts/ChainAssertions.sol";
import {Deployer} from "@eth-optimism-bedrock/scripts/Deployer.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {VmSafe} from "forge-std/Vm.sol";

contract SignFromJson is MultisigBuilder, JsonTxBuilderBase, Deployer {
    DeployConfig public cfg;
    VmSafe.AccountAccess[] accesses;

    function setUp() public override {
        super.setUp();
        string memory path = string.concat(
            vm.projectRoot(), "/lib/optimism/packages/contracts-bedrock/deploy-config/", deploymentContext, ".json"
        );
        cfg = new DeployConfig(path);
        vm.label(0x58Cc85b8D04EA49cC6DBd3CbFFd00B4B8D6cb3ef, "L1CrossDomainMessenger");
        vm.label(0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1, "L1StandardBridge");
        vm.label(0x90E9c4f8a994a250F6aEfd61CAFb4F2e895D458F, "L2OutputOracle");
        vm.label(0x868D59fF9710159C2B330Cc0fBDF57144dD7A13b, "OptimismMintableERC20Factory");
        vm.label(0x16Fc5058F25648194471939df75CF27A2fdC48BC, "OptimismPortal");
        vm.label(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538, "SystemConfig");
        vm.label(0xd83e03D576d23C9AEab8cC44Fa98d058D2176D1f, "L1ERC721Bridge");
        vm.label(0x79ADD5713B383DAa0a138d3C4780C7A1804a8090, "ProtocolVersions");
        vm.label(0xC2Be75506d5724086DEB7245bd260Cc9753911Be, "SuperchainConfig");
    }

    function signJson(string memory _path) public {
        _loadJson(_path);
        sign();
    }

    function runJson(string memory _path, bytes memory _signatures) public {
        _loadJson(_path);
        run(_signatures);
    }

    function testJson(string memory _path) public {
        _loadJson(_path);

        // Reduce the threshold to 1 so that we can run the script with just the caller's prevalidated signature.
        vm.store(_ownerSafe(), bytes32(uint256(4)), bytes32(uint256(1)));
        bytes memory _signature = prevalidatedSignature(msg.sender);

        vm.startStateDiffRecording();
        run(_signature);
        accesses = vm.stopAndReturnStateDiff();

        _checkStateDiff();
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        return _buildCallsFromJson();
    }

    // todo: allow passing this as a script argument.
    function _ownerSafe() internal view override returns (address) {
        return vm.envAddress("OWNER_SAFE");
    }

    function name() public pure override returns (string memory) {
        return "Sepolia-ExtendedPause";
    }

    function _postCheck() internal view override {
        Types.ContractSet memory proxies_ = Types.ContractSet({
            L1CrossDomainMessenger: 0x58Cc85b8D04EA49cC6DBd3CbFFd00B4B8D6cb3ef,
            L1StandardBridge: 0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1,
            L2OutputOracle: 0x90E9c4f8a994a250F6aEfd61CAFb4F2e895D458F,
            OptimismMintableERC20Factory: 0x868D59fF9710159C2B330Cc0fBDF57144dD7A13b,
            OptimismPortal: 0x16Fc5058F25648194471939df75CF27A2fdC48BC,
            SystemConfig: 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538,
            L1ERC721Bridge: 0xd83e03D576d23C9AEab8cC44Fa98d058D2176D1f,
            ProtocolVersions: 0x79ADD5713B383DAa0a138d3C4780C7A1804a8090,
            SuperchainConfig: 0xC2Be75506d5724086DEB7245bd260Cc9753911Be
        });

        ChainAssertions.postDeployAssertions({
            _prox: proxies_,
            _cfg: cfg,
            _l2OutputOracleStartingBlockNumber: 0,
            _l2OutputOracleStartingTimestamp: 1690493568,
            _vm: vm
        });
    }

    function _checkStateDiff() internal view {
        // Print the accesses just to show that we have them.
        // TODO: Define the correct accesses and write assertions for them.
        console.log(accesses.length, "accesses:");
        for (uint256 i = 0; i < accesses.length; i++) {
            console.log("accesses[%d]:", i);
            console.log("  account: %s", vm.toString(accesses[i].account));
            VmSafe.StorageAccess[] memory storageAccesses = accesses[i].storageAccesses;
            for (uint256 j = 0; j < storageAccesses.length; j++) {
                console.log("    storage slot:", vm.toString(storageAccesses[j].slot));
                console.log("       old:", vm.toString(storageAccesses[j].previousValue));
                console.log("       new:", vm.toString(storageAccesses[j].newValue));
            }
        }
    }
}
