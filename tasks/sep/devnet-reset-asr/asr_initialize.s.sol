// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {GnosisSafe as Safe} from "safe-contracts/GnosisSafe.sol";
import {Enum} from "safe-contracts/common/Enum.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm} from "forge-std/Vm.sol";
import {IDisputeGameFactory} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {ISystemConfig} from "@eth-optimism-bedrock/interfaces/L1/ISystemConfig.sol";
import {GameType, Hash} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {IMulticall3} from "forge-std/interfaces/IMultiCall3.sol";
import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";

interface IStorageSetter {
    function setBytes32(bytes32 slot, bytes32 value) external;
}

interface IAnchorStateRegistry {
    function systemConfig() external view returns (ISystemConfig);
    function disputeGameFactory() external view returns (IDisputeGameFactory);
    function initialize(
        ISystemConfig _systemConfig,
        IDisputeGameFactory _disputeGameFactory,
        Proposal memory _startingAnchorRoot,
        GameType _startingRespectedGameType
    ) external;
}

struct Proposal {
    Hash root;
    uint256 l2SequenceNumber;
}

contract ASRInitialize is Script {
    IMulticall3 constant multicall = IMulticall3(0xcA11bde05977b3631167028862bE2a173976CA11);

    IAnchorStateRegistry internal asrProxy;
    IProxyAdmin internal proxyAdmin;
    ISystemConfig internal systemConfigProxy;
    IDisputeGameFactory internal dgfProxy;
    Hash internal outputRoot;
    uint256 internal blockNumber;
    uint32 internal gameType;
    Proposal internal proposal;

    function setUp() public {
        asrProxy = IAnchorStateRegistry(vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY"));
        proxyAdmin = IProxyAdmin(vm.envAddress("PROXY_ADMIN"));
        systemConfigProxy = asrProxy.systemConfig();
        dgfProxy = asrProxy.disputeGameFactory();
        outputRoot = Hash.wrap(vm.envBytes32("OUTPUT_ROOT"));
        blockNumber = vm.envUint("BLOCK_NUMBER");
        gameType = uint32(vm.envUint("GAME_TYPE"));
        proposal = Proposal({root: outputRoot, l2SequenceNumber: blockNumber});
    }

    function run() external {
        address asrImplementation = proxyAdmin.getProxyImplementation(address(asrProxy));
        require(asrImplementation != address(0), "bad ASR proxy");

        IStorageSetter storageSetter = getStorageSetter();
        bytes memory storageSetterCalldata = abi.encodeCall(IStorageSetter.setBytes32, (bytes32(0x00), bytes32(0x00)));
        bytes memory proxyAdminCalldata0 = abi.encodeCall(
            IProxyAdmin.upgradeAndCall, (payable(address(asrProxy)), address(storageSetter), storageSetterCalldata)
        );
        console.log("Storage setter upgradeAndCall calldata to %s:", address(proxyAdmin));
        console.logBytes(proxyAdminCalldata0);

        bytes memory asrInitCalldata = abi.encodeCall(
            IAnchorStateRegistry.initialize, (systemConfigProxy, dgfProxy, proposal, GameType.wrap(gameType))
        );
        bytes memory proxyAdminCalldata1 =
            abi.encodeCall(IProxyAdmin.upgradeAndCall, (payable(address(asrProxy)), asrImplementation, asrInitCalldata));

        string memory a0 = serializeCalldata(address(proxyAdmin), proxyAdminCalldata0);
        string memory a1 = serializeCalldata(address(proxyAdmin), proxyAdminCalldata1);
        string[] memory txs = new string[](2);
        txs[0] = a0;
        txs[1] = a1;
        string memory json = "";
        json = stdJson.serialize("", "transactions", txs);
        json = stdJson.serialize("", "chainId", block.chainid);
        console.log(json);
    }

    function serializeCalldata(address _target, bytes memory _calldata) internal returns (string memory serialized_) {
        string memory json = "";
        json = stdJson.serialize("transactions", "to", _target);
        json = stdJson.serialize("transactions", "data", _calldata);
        json = stdJson.serialize("transactions", "value", string("0x0"));
        serialized_ = json;
    }

    function getStorageSetter() internal view returns (IStorageSetter storageSetter_) {
        if (block.chainid == 1) {
            storageSetter_ = IStorageSetter(0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC);
        } else if (block.chainid == 11155111) {
            // sepolia
            storageSetter_ = IStorageSetter(0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB);
        } else {
            revert("Unsupported chain");
        }
    }
}
