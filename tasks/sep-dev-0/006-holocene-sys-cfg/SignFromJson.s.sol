// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";

contract NestedSignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Safe contract for this task.
    address immutable proxyAdminOwnerSafe = vm.envAddress("OWNER_SAFE");

    address proxyAdmin;
    SystemConfig systemConfig;
    address systemConfigImpl;

    address l1XDMProxy;
    address l1ERC721BridgeProxy;
    address l1StandardBridgeProxy;
    address optimismPortalProxy;
    address optimismMintableERC20FactoryProxy;
    address batchInbox;
    uint256 startBlock;
    address dgfProxy;

    /// @notice Sets up the dgfProxy
    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep-dev-0/006-holocene-sys-cfg/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        string memory l2ChainId = "11155421";

        proxyAdmin = readContractAddress("ProxyAdmin", l2ChainId);
        systemConfigImpl = stdJson.readAddress(inputJson, "$.transactions[9].contractInputsValues._implementation");
        systemConfig = SystemConfig(readContractAddress("SystemConfigProxy", l2ChainId));

        l1XDMProxy = readContractAddress("L1CrossDomainMessengerProxy", l2ChainId);
        l1ERC721BridgeProxy = readContractAddress("L1ERC721BridgeProxy", l2ChainId);
        l1StandardBridgeProxy = readContractAddress("L1StandardBridgeProxy", l2ChainId);
        optimismPortalProxy = readContractAddress("OptimismPortalProxy", l2ChainId);
        optimismMintableERC20FactoryProxy = readContractAddress("OptimismMintableERC20FactoryProxy", l2ChainId);
        batchInbox = readBatchInboxAddress();
        startBlock = stdJson.readUint(inputJson, "$.transactions[7].contractInputsValues._block");
        dgfProxy = readContractAddress("DisputeGameFactoryProxy", l2ChainId);
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        exceptions = new address[](1);
        exceptions[0] = batchInbox;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = address(systemConfig);
        allowed[1] = proxyAdminOwnerSafe;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkSystemConfigProxy();
        console.log("All assertions passed!");
    }

    function checkSystemConfigProxy() internal {
        console.log("check system config proxy");

        vm.prank(proxyAdmin);
        address impl = Proxy(payable(address(systemConfig))).implementation();
        require(impl == systemConfigImpl, "sc-100");

        require(systemConfig.l1CrossDomainMessenger() == l1XDMProxy, "sc-200");
        require(systemConfig.l1ERC721Bridge() == l1ERC721BridgeProxy, "sc-300");
        require(systemConfig.l1StandardBridge() == l1StandardBridgeProxy, "sc-400");
        require(systemConfig.optimismPortal() == optimismPortalProxy, "sc-500");
        require(systemConfig.optimismMintableERC20Factory() == optimismMintableERC20FactoryProxy, "sc-600");
        require(systemConfig.batchInbox() == batchInbox, "sc-700");
        require(systemConfig.startBlock() == startBlock, "sc-800");
        require(systemConfig.disputeGameFactory() == dgfProxy, "sc-900");
    }

    function readContractAddress(string memory contractName, string memory chainId) internal view returns (address) {
        string memory addressesJson;

        // Read addresses json
        string memory path = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";

        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        return stdJson.readAddress(addressesJson, string.concat("$.", chainId, ".", contractName));
    }

    function readBatchInboxAddress() internal returns (address batchInbox_) {
        string memory path = "lib/superchain-registry/superchain/configs/sepolia-dev-0/oplabs-devnet-0.toml";
        string[] memory findAddressCmd = new string[](3);
        findAddressCmd[0] = "bash";
        findAddressCmd[1] = "-c";
        findAddressCmd[2] = string.concat(
            "cat ",
            path,
            " | ",
            "grep 'batch_inbox_addr'",
            " | ",
            "awk '{print $3}'",
            " | ",
            "tr -d '\"\n'"
        );
        bytes memory rawAddr = vm.ffi(findAddressCmd);

        string[] memory encodeAddrCommand = new string[](4);
        encodeAddrCommand[0] = "cast";
        encodeAddrCommand[1] = "abi-encode";
        encodeAddrCommand[2] = "f(address)";
        encodeAddrCommand[3] = vm.toString(rawAddr);
        bytes memory encodedAddr = vm.ffi(encodeAddrCommand);

        batchInbox_ = abi.decode(encodedAddr, (address));
    }
}
