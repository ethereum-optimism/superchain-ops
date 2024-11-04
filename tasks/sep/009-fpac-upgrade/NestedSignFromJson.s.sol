// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Constants, ResourceMetering} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {ProtocolVersion, ProtocolVersions} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {DisputeGameFactory, IDisputeGame} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(0xf64bc17485f0B4Ea5F06A96514182FC4cB561977));

    // Known EOAs to exclude from safety checks.
    address constant l2OutputOracleProposer = 0x49277EE36A024120Ee218127354c4a3591dc90A9; // cast call $L2OO "PROPOSER()(address)"
    address constant l2OutputOracleChallenger = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant systemConfigOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant batchSenderAddress = 0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c; // In registry genesis-system-configs
    address constant p2pSequencerAddress = 0x57CACBB0d30b01eb2462e5dC940c161aff3230D3; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address constant batchInboxAddress = 0xff00000000000000000000000000000011155420; // In registry yaml.

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function checkSemvers() internal view {
        // These are the expected semvers based on the `op-contracts/v1.4.0-rc.3` release.
        // https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2fv1.4.0-rc.3
        require(ISemver(proxies.OptimismPortal).version().eq("3.10.0"), "semver-100");
        require(ISemver(proxies.SystemConfig).version().eq("2.2.0"), "semver-200");
    }

    /// @notice Asserts that the SystemConfig is setup correctly
    function checkSystemConfig() internal view {
        console.log("Running assertions on the SystemConfig");

        require(proxies.SystemConfig.code.length != 0, "100");
        require(EIP1967Helper.getImplementation(proxies.SystemConfig).code.length != 0, "101");

        bytes32 l2OOSlot = bytes32(uint256(keccak256("systemconfig.l2outputoracle")) - 1);
        bytes32 dgfSlot = bytes32(uint256(keccak256("systemconfig.disputegamefactory")) - 1);

        require(vm.load(proxies.SystemConfig, l2OOSlot) == bytes32(0), "102");
        require(vm.load(proxies.SystemConfig, dgfSlot) == bytes32(uint256(uint160(proxies.DisputeGameFactory))), "103");
    }

    /// @notice Asserts that the DisputeGameFactory is setup correctly
    function checkDisputeGameFactory() internal view {
        console.log("Running assertions on the DisputeGameFactory");

        require(proxies.DisputeGameFactory.code.length != 0, "200");
        require(EIP1967Helper.getImplementation(proxies.DisputeGameFactory).code.length != 0, "201");

        DisputeGameFactory factory = DisputeGameFactory(payable(proxies.DisputeGameFactory));
        FaultDisputeGame fdgImpl = FaultDisputeGame(address(factory.gameImpls(GameTypes.CANNON)));
        FaultDisputeGame permissionedGameImpl = FaultDisputeGame(address(factory.gameImpls(GameTypes.PERMISSIONED_CANNON)));

        // Require that the game implementations are the correct versions.
        require(ISemver(address(fdgImpl)).version().eq("1.2.0"), "202");
        require(ISemver(address(permissionedGameImpl)).version().eq("1.2.0"), "203");
        
        // Require that the MIPS VM is the correct version.
        require(ISemver(address(fdgImpl.vm())).version().eq("1.0.1"), "204");
        require(ISemver(address(permissionedGameImpl.vm())).version().eq("1.0.1"), "205");

        // Require that the Preimage Oracle is the correct version.
        require(ISemver(address(fdgImpl.vm().oracle())).version().eq("1.0.0"), "206");
        require(ISemver(address(permissionedGameImpl.vm().oracle())).version().eq("1.0.0"), "207");

        // Require that the anchor state registry is the correct version.
        require(ISemver(address(fdgImpl.anchorStateRegistry())).version().eq("1.0.0"), "208");
        require(ISemver(address(permissionedGameImpl.anchorStateRegistry())).version().eq("1.0.0"), "209");

        // Require that the DelayedWeth contract is the correct version.
        require(ISemver(address(fdgImpl.weth())).version().eq("1.0.0"), "210");
        require(ISemver(address(permissionedGameImpl.weth())).version().eq("1.0.0"), "211");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkSemvers();

        checkSystemConfig();
        checkDisputeGameFactory();

        console.log("All assertions passed!");
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
        address[] memory shouldHaveCodeExceptions = new address[](6 + numberOfSafeSignersWithNoCode);

        shouldHaveCodeExceptions[0] = l2OutputOracleProposer;
        shouldHaveCodeExceptions[1] = l2OutputOracleChallenger;
        shouldHaveCodeExceptions[2] = systemConfigOwner;
        shouldHaveCodeExceptions[3] = batchSenderAddress;
        shouldHaveCodeExceptions[4] = p2pSequencerAddress;
        shouldHaveCodeExceptions[5] = batchInboxAddress;

        // And finally, we append the Safe signer exceptions.
        for (uint256 i = 0; i < safeSignersWithNoCode.length; i++) {
            shouldHaveCodeExceptions[6 + i] = safeSignersWithNoCode[i];
        }

        return shouldHaveCodeExceptions;
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/extra/addresses/${l1ChainName}/${l2ChainName}.json
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        // Read addresses json
        string memory path = string.concat(
            "/lib/superchain-registry/superchain/extra/addresses/", l1ChainName, "/", l2ChainName, ".json"
        );
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        _proxies.OptimismPortal = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.SystemConfig = stdJson.readAddress(addressesJson, "$.SystemConfigProxy");
        _proxies.DisputeGameFactory = stdJson.readAddress(addressesJson, "$.DisputeGameFactoryProxy");

        // Read superchain.yaml
        string[] memory inputs = new string[](4);
        inputs[0] = "yq";
        inputs[1] = "-o";
        inputs[2] = "json";
        inputs[3] = string.concat("lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.yaml");

        addressesJson = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(addressesJson, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdJson.readAddress(addressesJson, "$.superchain_config_addr");
    }
}
