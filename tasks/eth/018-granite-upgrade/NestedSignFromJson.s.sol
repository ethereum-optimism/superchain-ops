// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";

interface IASR {
    function superchainConfig() external view returns (address superchainConfig_);
}

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "mainnet";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    address constant expectedLivenessGuard = 0x24424336F04440b1c28685a38303aC33C9D14a25;

    /// @notice Verify against https://github.com/ethereum-optimism/superchain-registry/blob/9c9ba657a4d26e1f80bada8e8e94a77df643018c/superchain/configs/mainnet/op.toml#L38
    address constant systemConfigOwner = 0x847B5c174615B1B7fDF770882256e2D3E95b9D92;
    address constant batchSenderAddress = 0x6887246668a3b87F54DeB3b94Ba47a6f63F32985; // In registry genesis-system-configs

    /// @notice Verify these against https://github.com/ethereum-optimism/superchain-registry/blob/9c9ba657a4d26e1f80bada8e8e94a77df643018c/superchain/configs/mainnet/op.toml.
    address constant p2pSequencerAddress = 0xAAAA45d9549EDA09E70937013520214382Ffc4A2;
    address constant batchInboxAddress = 0xFF00000000000000000000000000000000000010;

    // See https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/extra/addresses/mainnet/op.json#L12
    bytes32 constant expectedAbsolutePrestate = hex"038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c";

    // Verify addresses in gov proposal - https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733#p-39463-impacted-components-8
    address constant expectedFDG = 0xA6f3DFdbf4855a43c529bc42EDE96797252879af;
    address constant expectedPermissionedFDG = 0x050ed6F6273c7D836a111E42153BC00D0380b87d;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added, and they are allowed
        // to have code AND to have no code.
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();

        // To make sure we probably handle all signers whether or not they have code, first we count
        // the number of signers that have no code.
        uint256 numberOfSafeSignersWithNoCode;
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                numberOfSafeSignersWithNoCode++;
            }
        }

        // Then we extract those EOA addresses into a dedicated array.
        uint256 trackedSignersWithNoCode;
        address[] memory safeSignersWithNoCode = new address[](numberOfSafeSignersWithNoCode);
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                safeSignersWithNoCode[trackedSignersWithNoCode] = securityCouncilSafeOwners[i];
                trackedSignersWithNoCode++;
            }
        }

        // Here we add the standard (non Safe signer) exceptions.
        address[] memory shouldHaveCodeExceptions = new address[](4 + numberOfSafeSignersWithNoCode);

        shouldHaveCodeExceptions[0] = systemConfigOwner;
        shouldHaveCodeExceptions[1] = batchSenderAddress;
        shouldHaveCodeExceptions[2] = p2pSequencerAddress;
        shouldHaveCodeExceptions[3] = batchInboxAddress;

        // And finally, we append the Safe signer exceptions.
        for (uint256 i = 0; i < safeSignersWithNoCode.length; i++) {
            shouldHaveCodeExceptions[4 + i] = safeSignersWithNoCode[i];
        }

        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](6);
        allowed[0] = address(proxies.DisputeGameFactory);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(securityCouncilSafe);
        allowed[3] = address(fndSafe);
        allowed[4] = expectedLivenessGuard;
        allowed[5] = proxies.AnchorStateRegistry;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _checkDisputeGameImplementations();
        _checkDelayedWETH();
        _checkAnchorStateRegistry();

        console.log("All assertions passed!");
    }

    /// @notice Reads the contract addresses from the superchain registry.
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory chainConfig;
        string memory path =
            string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        _proxies.SuperchainConfig = stdToml.readAddress(chainConfig, "$.superchain_config_addr");

        path = string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/", l2ChainName, ".toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        _proxies.AnchorStateRegistry = stdToml.readAddress(chainConfig, "$.addresses.AnchorStateRegistryProxy");
        _proxies.DisputeGameFactory = stdToml.readAddress(chainConfig, "$.addresses.DisputeGameFactoryProxy");
    }

    function _checkDisputeGameImplementations() internal view {
        console.log("check dispute game implementations");

        DisputeGameFactory dgfProxy = DisputeGameFactory(proxies.DisputeGameFactory);
        FaultDisputeGame faultDisputeGame = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        PermissionedDisputeGame permissionedDisputeGame =
            PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));

        require(expectedFDG == address(faultDisputeGame), "game-001");
        require(expectedPermissionedFDG == address(permissionedDisputeGame), "game-002");

        require(faultDisputeGame.version().eq("1.3.0"), "game-100");
        require(permissionedDisputeGame.version().eq("1.3.0"), "game-200");

        require(faultDisputeGame.absolutePrestate().raw() == expectedAbsolutePrestate, "game-300");
        require(permissionedDisputeGame.absolutePrestate().raw() == expectedAbsolutePrestate, "game-400");
    }

    function _checkDelayedWETH() internal view {
        DisputeGameFactory dgfProxy = DisputeGameFactory(proxies.DisputeGameFactory);
        FaultDisputeGame fdg = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        require(ISemver(address(fdg.weth())).version().eq("1.1.0"), "weth-100");

        PermissionedDisputeGame soyFDG =
            PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));
        require(ISemver(address(soyFDG.weth())).version().eq("1.1.0"), "weth-200");

        require(address(fdg.weth()) != address(soyFDG.weth()), "weth-300");
    }

    function _checkAnchorStateRegistry() internal view {
        require(ISemver(proxies.AnchorStateRegistry).version().eq("2.0.0"), "asr-100");
        require(IASR(proxies.AnchorStateRegistry).superchainConfig() == proxies.SuperchainConfig, "asr-200");
    }
}
