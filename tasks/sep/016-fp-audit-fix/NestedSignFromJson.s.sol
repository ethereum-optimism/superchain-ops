// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
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
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    address constant livenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;

    address constant systemConfigOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant batchSenderAddress = 0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c; // In registry genesis-system-configs
    address constant p2pSequencerAddress = 0x57CACBB0d30b01eb2462e5dC940c161aff3230D3; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address constant batchInboxAddress = 0xff00000000000000000000000000000011155420; // In registry yaml.

    // See https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/extra/addresses/sepolia/op.json#L12
    DisputeGameFactory constant dgfProxy = DisputeGameFactory(0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1);
    address constant anchorStateRegistryProxy = 0x218CD9489199F321E1177b56385d333c5B598629;

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
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(securityCouncilSafe);
        allowed[3] = address(fndSafe);
        allowed[4] = livenessGuard;
        allowed[5] = anchorStateRegistryProxy;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
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

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/${l1ChainName}/${l2ChainName}.toml
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory chainConfig;
        string memory path = string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        _proxies.SuperchainConfig = stdToml.readAddress(chainConfig, "$.superchain_config_addr");
    }

    function _checkDisputeGameImplementations() internal view {
        console.log("check dispute game implementations");

        FaultDisputeGame faultDisputeGame = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        PermissionedDisputeGame permissionedDisputeGame =
            PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));

        require(faultDisputeGame.version().eq("1.3.0"), "game-100");
        require(permissionedDisputeGame.version().eq("1.3.0"), "game-200");

        require(
            faultDisputeGame.absolutePrestate().raw()
                == bytes32(0x030de10d9da911a2b180ecfae2aeaba8758961fc28262ce989458c6f9a547922),
            "game-300"
        );
        require(
            permissionedDisputeGame.absolutePrestate().raw()
                == bytes32(0x030de10d9da911a2b180ecfae2aeaba8758961fc28262ce989458c6f9a547922),
            "game-400"
        );
    }

    function _checkDelayedWETH() internal view {
        FaultDisputeGame fdg = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        require(ISemver(address(fdg.weth())).version().eq("1.1.0"), "weth-100");

        PermissionedDisputeGame soyFDG =
            PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));
        require(ISemver(address(soyFDG.weth())).version().eq("1.1.0"), "weth-200");

        require(address(fdg.weth()) != address(soyFDG.weth()), "weth-300");
    }

    function _checkAnchorStateRegistry() internal view {
        require(ISemver(anchorStateRegistryProxy).version().eq("2.0.0"), "asr-100");
        require(IASR(anchorStateRegistryProxy).superchainConfig() == proxies.SuperchainConfig, "asr-200");
    }
}
