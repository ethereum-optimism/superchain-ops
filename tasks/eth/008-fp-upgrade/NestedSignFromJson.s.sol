// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {ProtocolVersion, ProtocolVersions} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {OptimismPortal2} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {L1CrossDomainMessenger} from "@eth-optimism-bedrock/src/L1/L1CrossDomainMessenger.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";
import {AddressManager} from "@eth-optimism-bedrock/src/legacy/AddressManager.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {ResourceMetering} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {IGnosisSafe, Enum} from "@eth-optimism-bedrock/scripts/interfaces/IGnosisSafe.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#guardian
    address constant superchainConfigGuardian = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L12
    address constant p2pSequencerAddress = 0xAAAA45d9549EDA09E70937013520214382Ffc4A2;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L13
    address constant batchInboxAddress = 0xFF00000000000000000000000000000000000010;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#batcher
    address constant batchSenderAddress = 0x6887246668a3b87F54DeB3b94Ba47a6f63F32985;

    /// @notice Verify against lib/superchain-registry/superchain/extra/addresses/mainnet/op.json
    address constant systemConfigOwner = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L35
    uint256 constant l2GenesisBlockGasLimit = 0x1c9c380;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L37
    uint256 constant gasPriceOracleOverhead = 0;

    /// @notice Verify with `cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "scalar()(bytes32)"`. We don't link to
    /// the deploy-config here because it needs to be updated to account for the new way the scalar
    /// is encoded post-ecotone. But we don't want this parameter to change, so we hardcode the
    /// existing value (fetched with the above command) here.
    uint256 constant gasPriceOracleScalar = 0x10000000000000000000000000000000000000000000000000c5fc500000558;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L44
    uint256 constant systemConfigStartBlock = 17422444;

    // Verify against the `DisputeGameFactoryProxy` in the Fault Proofs governance post - https://gov.optimism.io/t/upgrade-proposal-fault-proofs/8161
    address constant dgfProxy = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory shouldHaveCodeExceptions = new address[](4);

        shouldHaveCodeExceptions[0] = systemConfigOwner;
        shouldHaveCodeExceptions[1] = batchSenderAddress;
        shouldHaveCodeExceptions[2] = p2pSequencerAddress;
        shouldHaveCodeExceptions[3] = batchInboxAddress;

        return shouldHaveCodeExceptions;
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/extra/addresses/mainnet/op.json
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        // Read addresses json
        try vm.readFile(
            string.concat(vm.projectRoot(), "/lib/superchain-registry/superchain/extra/addresses/mainnet/op.json")
        ) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert("Failed to read lib/superchain-registry/superchain/extra/addresses/mainnet/op.json");
        }

        _proxies.L1CrossDomainMessenger = stdJson.readAddress(addressesJson, "$.L1CrossDomainMessengerProxy");
        _proxies.L1StandardBridge = stdJson.readAddress(addressesJson, "$.L1StandardBridgeProxy");
        _proxies.OptimismMintableERC20Factory =
            stdJson.readAddress(addressesJson, "$.OptimismMintableERC20FactoryProxy");
        _proxies.OptimismPortal = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.OptimismPortal2 = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.SystemConfig = stdJson.readAddress(addressesJson, "$.SystemConfigProxy");
        _proxies.L1ERC721Bridge = stdJson.readAddress(addressesJson, "$.L1ERC721BridgeProxy");
        _proxies.DisputeGameFactory = dgfProxy;

        // Read superchain.yaml
        string[] memory inputs = new string[](4);
        inputs[0] = "yq";
        inputs[1] = "-o";
        inputs[2] = "json";
        inputs[3] = "lib/superchain-registry/superchain/configs/mainnet/superchain.yaml";

        addressesJson = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(addressesJson, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdJson.readAddress(addressesJson, "$.superchain_config_addr");
    }
 
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload)
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");
        checkSemvers();
        checkStateDiff(accesses);
        checkSystemConfig();
        checkOptimismPortal();
        console.log("All assertions passed!");
    }

    function checkStateDiff(Vm.AccountAccess[] memory accountAccesses) internal view override {
        require(accountAccesses.length > 0, "No account accesses");

        super.checkStateDiff(accountAccesses);

        // Assert that no other OP Contracts other than the SystemConfig and the OptimismPortal are accessed
        for (uint256 i; i < accountAccesses.length; i++) {
            Vm.AccountAccess memory accountAccess = accountAccesses[i];
            require(
                accountAccess.oldBalance == accountAccess.newBalance,
                string.concat("Unexpected balance change: ", vm.toString(accountAccess.account))
            );
            require(
                accountAccess.kind != VmSafe.AccountAccessKind.SelfDestruct,
                string.concat("Self-destructed account: ", vm.toString(accountAccess.account))
            );

            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                Vm.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];

                address account = storageAccess.account;
                require(account != proxies.L1CrossDomainMessenger, "state-000");
                require(account != proxies.L1ERC721Bridge, "state-100");
                require(account != proxies.L1StandardBridge, "state-200");
                require(account != proxies.OptimismMintableERC20Factory, "state-300");
            }
        }
    }

    function checkSemvers() internal view {
        // These are the expected semvers based on the `op-contracts/v1.4.0-rc.4` release.
        // https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.4.0-rc.4
        require(ISemver(proxies.L1CrossDomainMessenger).version().eq("2.3.0"), "semver-100");
        require(ISemver(proxies.L1ERC721Bridge).version().eq("2.1.0"), "semver-700");
        require(ISemver(proxies.L1StandardBridge).version().eq("2.1.0"), "semver-200");
        require(ISemver(proxies.OptimismMintableERC20Factory).version().eq("1.9.0"), "semver-400");
        require(ISemver(proxies.OptimismPortal).version().eq("3.10.0"), "semver-500");
        require(ISemver(proxies.SystemConfig).version().eq("2.2.0"), "semver-600");
        require(ISemver(proxies.ProtocolVersions).version().eq("1.0.0"), "semver-800");
        require(ISemver(proxies.SuperchainConfig).version().eq("1.1.0"), "semver-900");
    }

    /// @notice Asserts that the SystemConfig is setup correctly
    ///         Assertions are similar to the 006-MCP-L1 upgrade
    function checkSystemConfig() internal view {
        console.log("Running chain assertions on the SystemConfig");

        require(proxies.SystemConfig.code.length != 0, "200");
        require(EIP1967Helper.getImplementation(proxies.SystemConfig).code.length != 0, "201");

        SystemConfig configToCheck = SystemConfig(proxies.SystemConfig);
        require(configToCheck.owner() == superchainConfigGuardian, "300");
        require(configToCheck.overhead() == gasPriceOracleOverhead, "400");
        require(configToCheck.scalar() == gasPriceOracleScalar, "500");
        require(configToCheck.batcherHash() == bytes32(uint256(uint160(batchSenderAddress))), "600");
        require(configToCheck.gasLimit() == uint64(l2GenesisBlockGasLimit), "700");
        require(configToCheck.unsafeBlockSigner() == p2pSequencerAddress, "800");

        ResourceMetering.ResourceConfig memory resourceConfigToCheck = configToCheck.resourceConfig();
        // Check _config
        require(
            keccak256(abi.encode(resourceConfigToCheck)) == keccak256(abi.encode(Constants.DEFAULT_RESOURCE_CONFIG())),
            "900"
        );
        require(configToCheck.startBlock() == systemConfigStartBlock, "1500");
        require(configToCheck.batchInbox() == batchInboxAddress, "1600");

        // Check _addresses
        require(configToCheck.l1CrossDomainMessenger() == proxies.L1CrossDomainMessenger, "1700");
        require(configToCheck.l1CrossDomainMessenger().code.length != 0, "1740");

        // L1CrossDomainMessenger is a ResolvedDelegateProxy and that has no getters, so we hardcode some info needed here.
        AddressManager addressManager = AddressManager(0xdE1FCfB0851916CA5101820A69b13a4E276bd81F); // https://github.com/ethereum-optimism/superchain-registry/blob/4c005f16ee1b100afc08a35a2e418d849bea044a/superchain/extra/addresses/mainnet/op.json#L2
        address l1xdmImplementation = addressManager.getAddress("OVM_L1CrossDomainMessenger");
        require(l1xdmImplementation.code.length != 0, "1750");

        require(configToCheck.l1ERC721Bridge() == proxies.L1ERC721Bridge, "1800");
        require(configToCheck.l1ERC721Bridge().code.length != 0, "1801");
        require(EIP1967Helper.getImplementation(configToCheck.l1ERC721Bridge()).code.length != 0, "1802");

        require(configToCheck.l1StandardBridge() == proxies.L1StandardBridge, "1900");
        require(configToCheck.l1StandardBridge().code.length != 0, "1901");
        require(EIP1967Helper.getImplementation(configToCheck.l1StandardBridge()).code.length != 0, "1902");

        require(configToCheck.optimismPortal() == proxies.OptimismPortal, "2100");
        require(configToCheck.optimismPortal().code.length != 0, "2101");
        require(EIP1967Helper.getImplementation(configToCheck.optimismPortal()).code.length != 0, "2102");

        require(configToCheck.optimismMintableERC20Factory() == proxies.OptimismMintableERC20Factory, "2200");
        require(configToCheck.optimismMintableERC20Factory().code.length != 0, "2201");
        require(EIP1967Helper.getImplementation(configToCheck.optimismMintableERC20Factory()).code.length != 0, "2202");

        require(configToCheck.disputeGameFactory() == proxies.DisputeGameFactory, "2300");
        require(configToCheck.disputeGameFactory().code.length != 0, "2301");
        require(EIP1967Helper.getImplementation(configToCheck.disputeGameFactory()).code.length != 0, "2302");

        // Ensure that the old l2outputoracle slot is cleared
        bytes32 l2OutputOracleSlot = vm.load(address(configToCheck), bytes32(uint256(keccak256("systemconfig.l2outputoracle")) - 1));
        require(address(uint160(uint256(l2OutputOracleSlot))) == address(0), "2400");
    }

    function checkOptimismPortal() internal view {
        console.log("Running chain assertions on the OptimismPortal");

        // NOTE: proxies.OptimismPortal2 == proxies.OptimismPortal
        require(proxies.OptimismPortal.code.length != 0, "5700");
        require(EIP1967Helper.getImplementation(proxies.OptimismPortal).code.length != 0, "5701");

        OptimismPortal2 portalToCheck = OptimismPortal2(payable(proxies.OptimismPortal));

        require(address(portalToCheck.disputeGameFactory()) == proxies.DisputeGameFactory, "5800");
        require(address(portalToCheck.disputeGameFactory()).code.length != 0, "5801");
        require(EIP1967Helper.getImplementation(address(portalToCheck.disputeGameFactory())).code.length != 0, "5802");

        checkOptimismPortal2();
    }

    // @notice checkOptimismPortal is broken up to avoid stack too deep solc errors
    function checkOptimismPortal2() internal view {
        OptimismPortal2 portalToCheck = OptimismPortal2(payable(proxies.OptimismPortal));
        require(address(portalToCheck.systemConfig()) == proxies.SystemConfig, "5900");
        require(address(portalToCheck.systemConfig()).code.length != 0, "5901");
        require(EIP1967Helper.getImplementation(address(portalToCheck.systemConfig())).code.length != 0, "5902");

        require(portalToCheck.guardian() == superchainConfigGuardian, "6000");
        require(portalToCheck.guardian().code.length != 0, "6001"); // This is a Safe, no need to check the implementation.

        require(address(portalToCheck.superchainConfig()) == address(proxies.SuperchainConfig), "6100");
        require(address(portalToCheck.superchainConfig()).code.length != 0, "6101");
        require(EIP1967Helper.getImplementation(address(portalToCheck.superchainConfig())).code.length != 0, "6102");

        require(portalToCheck.paused() == SuperchainConfig(proxies.SuperchainConfig).paused(), "6200");

        require(portalToCheck.l2Sender() == Constants.DEFAULT_L2_SENDER, "6300");

        require(portalToCheck.respectedGameType().raw() == GameTypes.CANNON.raw(), "6400");

        require(portalToCheck.respectedGameTypeUpdatedAt() != 0, "6500");
    }
}
