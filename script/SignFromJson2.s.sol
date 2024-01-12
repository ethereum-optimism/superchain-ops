// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {ChainAssertions, Types, DeployConfig} from "@eth-optimism/scripts/ChainAssertions.sol";
import {Deployer} from "@eth-optimism/scripts/Deployer.sol";
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
        vm.label(0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC, "StorageSetter");
        vm.label(0xfb1bffC9d739B8D520DaF37dF666da4C687191EA, "GnosisSafeL2");
        vm.label(0x9bFE9c5609311DF1c011c47642253B78a4f33F4B, "Addressmanager");
        vm.label(0x58Cc85b8D04EA49cC6DBd3CbFFd00B4B8D6cb3ef, "L1CrossDomainMessengerProxy");
        vm.label(0xC3c7E6f4ad6a593a9731a39FA883eC1999d7D873, "L1CrossDomainMessengerImpl");
        vm.label(0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1, "L1StandardBridgeProxy");
        vm.label(0xE19C7a2C0Bb32287731Ea75dA9B1C836815964F1, "L1StandardBridgeImpl");
        vm.label(0x90E9c4f8a994a250F6aEfd61CAFb4F2e895D458F, "L2OutputOracleProxy");
        vm.label(0x83aEb8B156cD90E64C702781C84A681DADb1DDe2, "L2OutputOracleImpl");
        vm.label(0x868D59fF9710159C2B330Cc0fBDF57144dD7A13b, "OptimismMintableERC20FactoryProxy");
        // vm.label(0x868D59fF9710159C2B330Cc0fBDF57144dD7A13b, "OptimismMintableERC20FactoryImpl");
        vm.label(0x16Fc5058F25648194471939df75CF27A2fdC48BC, "OptimismPortalProxy");
        vm.label(0x592B7D3255a8037307d23C16cC8c13a9563c8Ab1, "OptimismPortalImpl");
        vm.label(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538, "SystemConfigProxy");
        vm.label(0xce77d580E0bEFbb1561376A722217017651B9dbF, "SystemConfigImpl");
        vm.label(0xd83e03D576d23C9AEab8cC44Fa98d058D2176D1f, "L1ERC721BridgeProxy");
        vm.label(0x532Cad52e1f812EEB9c9A9571E07Fef55993FEfA, "L1ERC721BridgeImpl");
        vm.label(0x79ADD5713B383DAa0a138d3C4780C7A1804a8090, "ProtocolVersionsProxy");
        vm.label(0xC2Be75506d5724086DEB7245bd260Cc9753911Be, "SuperchainConfigProxy");
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

    mapping(address => bool) public loggedAccountAccesses;
    // mapping(address => bool) public loggedAccountDiffs;
    mapping(address => bool) public loggedAccountHasDiffs;

    function _checkStateDiff() internal {
        // Print the accesses just to show that we have them.
        // TODO: Define the correct accesses and write assertions for them.
        for (uint256 i = 0; i < accesses.length; i++) {
            VmSafe.StorageAccess[] memory storageAccesses = accesses[i].storageAccesses;
            if (!loggedAccountAccesses[accesses[i].account]) {
                loggedAccountAccesses[accesses[i].account] = true;
                console.log("Showing diffs for..........");
                console.log(
                    "Contract: %s at address: %s", vm.getLabel(accesses[i].account), vm.toString(accesses[i].account)
                );
                console.log("=============================");
            }
            for (uint256 j = 0; j < storageAccesses.length; j++) {
                if (storageAccesses[j].previousValue != storageAccesses[j].newValue) {
                    console.log("    storage slot:", vm.toString(storageAccesses[j].slot));
                    console.log("       old:", vm.toString(storageAccesses[j].previousValue));
                    console.log("       new:", vm.toString(storageAccesses[j].newValue));
                    console.log("");
                    loggedAccountHasDiffs[accesses[i].account] = true;
                }
                if (j == storageAccesses.length - 1 && loggedAccountHasDiffs[accesses[i].account] == false) {
                    // console.log("No diffs");
                }
            }
            // console.log("");
        }
    }
}
