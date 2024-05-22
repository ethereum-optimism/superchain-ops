// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Constants, ResourceMetering} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {L2OutputOracle} from "@eth-optimism-bedrock/src/L1/L2OutputOracle.sol";
import {ProtocolVersion, ProtocolVersions} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {OptimismPortal} from "@eth-optimism-bedrock/src/L1/OptimismPortal.sol";
import {L1CrossDomainMessenger} from "@eth-optimism-bedrock/src/L1/L1CrossDomainMessenger.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

// Interface used to read various data from contracts. This is an aggregation of methods from
// various protocol contracts for simplicity, and does not map to the full ABI of any single contract.
interface IFetcher {
    function overhead() external returns (uint256); // SystemConfig
    function scalar() external returns (uint256); // SystemConfig
    function guardian() external returns (address); // SuperchainConfig
    function L2_BLOCK_TIME() external returns (uint256); // L2OutputOracle
    function SUBMISSION_INTERVAL() external returns (uint256); // L2OutputOracle
    function FINALIZATION_PERIOD_SECONDS() external returns (uint256); // L2OutputOracle
    function startingTimestamp() external returns (uint256); // L2OutputOracle
    function startingBlockNumber() external returns (uint256); // L2OutputOracle
    function owner() external returns (address); // ProtocolVersions
    function required() external returns (uint256); // ProtocolVersions
    function recommended() external returns (uint256); // ProtocolVersions
}

// In Proxy.sol, the `admin()` method is not view because it's a delegatecall if the caller is
// not the admin or address(0). We know our call here will not be mutable, so to avoid removing the
// view modifier from `_postCheck` we use this interface to fetch the admin instead of the actual
// `Proxy` contract interface.
interface IProxyAdminView {
    function admin() external view returns (address);
}

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(0xf64bc17485f0B4Ea5F06A96514182FC4cB561977));
    GnosisSafe foundationSafe = GnosisSafe(payable(0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B));
    GnosisSafe proxyAdminOwnerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    // Contracts we need to check, which are not in the superchain registry


    // Known EOAs to exclude from safety checks.
    address constant l2OutputOracleProposer = 0x49277EE36A024120Ee218127354c4a3591dc90A9; // cast call $L2OO "PROPOSER()(address)"
    address constant l2OutputOracleChallenger = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant systemConfigOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant batchSenderAddress = 0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c; // In registry genesis-system-configs
    address constant p2pSequencerAddress = 0x57CACBB0d30b01eb2462e5dC940c161aff3230D3; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address constant batchInboxAddress = 0xff00000000000000000000000000000011155420; // In registry yaml.

    // Hardcoded data that should not change after execution.
    uint256 l2GenesisBlockGasLimit = 30e6;
    uint256 xdmSenderSlotNumber = 204; // Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L93-L99

    // Other data we use.
    address superchainConfigGuardian; // We fetch this during setUp and expect it to change.
    uint256 constant systemConfigStartBlock = 4071248;

    Types.ContractSet proxies;

    // This gives the initial fork, so we can use it to switch back after fetching data.
    uint256 initialFork;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();

        // Fetch variables that are not expected to change from an older block.
        initialFork = vm.activeFork();
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), block.number - 10); // Arbitrary recent block.

        vm.selectFork(initialFork);
    }

    function checkSemvers() internal view {
        // These are the expected semvers based on the `op-contracts/v1.3.0` release.
        // https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2fv1.3.0
        require(ISemver(proxies.L1CrossDomainMessenger).version().eq("2.3.0"), "semver-100");
        require(ISemver(proxies.L1StandardBridge).version().eq("2.1.0"), "semver-200");
        require(ISemver(proxies.L2OutputOracle).version().eq("1.8.0"), "semver-300");
        require(ISemver(proxies.OptimismMintableERC20Factory).version().eq("1.9.0"), "semver-400");
        require(ISemver(proxies.OptimismPortal).version().eq("3.10.0"), "semver-500");
        require(ISemver(proxies.SystemConfig).version().eq("2.2.0"), "semver-600");
        require(ISemver(proxies.L1ERC721Bridge).version().eq("2.1.0"), "semver-700");
        require(ISemver(proxies.ProtocolVersions).version().eq("1.0.0"), "semver-800");
        require(ISemver(proxies.SuperchainConfig).version().eq("1.1.0"), "semver-900");
    }

   
    /// @notice Asserts the OptimismPortal emitted correct event
    function checkOptimismPortal() internal pure {
        console.log("Running assertions on the OptimismPortal");

        // require(proxies.OptimismPortal.code.length != 0, "5700");
        // require(EIP1967Helper.getImplementation(proxies.OptimismPortal).code.length != 0, "5701");

        // OptimismPortal portalToCheck = OptimismPortal(payable(proxies.OptimismPortal));

        // require(address(portalToCheck.systemConfig()) == proxies.SystemConfig, "6000");
        // require(address(portalToCheck.systemConfig()).code.length != 0, "6100");
        // require(EIP1967Helper.getImplementation(address(portalToCheck.systemConfig())).code.length != 0, "6200");

        // // In this playbook, we expect the guardian to change. We comment out this check instead of
        // // changing to `!=` because the change is verified in the validations file, and because if
        // // we had `!=`, this would error when simulating on the `just approve` call.
        // // require(portalToCheck.guardian() == superchainConfigGuardian, "6300");
        // require(portalToCheck.guardian().code.length != 0, "6350"); // This is a Safe, no need to check the implementation.

        // require(address(portalToCheck.superchainConfig()) == address(proxies.SuperchainConfig), "6400");
        // require(address(portalToCheck.superchainConfig()).code.length != 0, "6401");
        // require(EIP1967Helper.getImplementation(address(portalToCheck.superchainConfig())).code.length != 0, "6402");

        // require(portalToCheck.paused() == SuperchainConfig(proxies.SuperchainConfig).paused(), "6500");
        // require(portalToCheck.l2Sender() == Constants.DEFAULT_L2_SENDER, "6600");
    }

    function checkProxyAdminOwnerSafe() internal view {
        // In Proxy.sol, the `admin()` method is not view because it's a delegatecall if the caller is
        // not the admin or address(0). We know our call here will not be mutable, so to avoid removing the
        // view modifier from `_postCheck` we use the IProxyAdminView interface to fetch the admin,
        // instead of the actual `Proxy` contract interface. However, we need to prank for the call
        // to come from the zero address, and prank is also not a view method. Therefore, we instead
        // prank using a low-level staticcall to preserve the view modifier.
        (bool ok,) = address(vm).staticcall(abi.encodeWithSignature("prank(address)", address(0)));
        address proxyAdmin = IProxyAdminView(payable(proxies.SystemConfig)).admin();
        require(ok, "checkProxyAdminOwnerSafe: low-level prank failed");
        address proxyAdminOwner = ProxyAdmin(proxyAdmin).owner();
        require(proxyAdminOwner == address(proxyAdminOwnerSafe), "checkProxyAdminOwnerSafe-260");

        require(proxyAdminOwnerSafe.isOwner(address(foundationSafe)), "checkProxyAdminOwnerSafe-300");
        require(proxyAdminOwnerSafe.isOwner(address(securityCouncilSafe)), "checkProxyAdminOwnerSafe-400");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkSemvers();

        checkOptimismPortal();
        checkProxyAdminOwnerSafe();

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

        _proxies.L1CrossDomainMessenger = stdJson.readAddress(addressesJson, "$.L1CrossDomainMessengerProxy");
        _proxies.L1StandardBridge = stdJson.readAddress(addressesJson, "$.L1StandardBridgeProxy");
        _proxies.L2OutputOracle = stdJson.readAddress(addressesJson, "$.L2OutputOracleProxy");
        _proxies.OptimismMintableERC20Factory =
            stdJson.readAddress(addressesJson, "$.OptimismMintableERC20FactoryProxy");
        _proxies.OptimismPortal = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.OptimismPortal2 = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.SystemConfig = stdJson.readAddress(addressesJson, "$.SystemConfigProxy");
        _proxies.L1ERC721Bridge = stdJson.readAddress(addressesJson, "$.L1ERC721BridgeProxy");

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
