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
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {stdToml} from "forge-std/StdToml.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    using LibString for string;

    address constant optimismPortalGuardian = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;

    /// @notice Verify against https://github.com/ethereum-optimism/superchain-registry/blob/21506ecedf6e83410d12c7cc406685ac061a2a74/superchain/configs/mainnet/base.toml#L44
    address constant p2pSequencerAddress = 0xAf6E19BE0F9cE7f8afd49a1824851023A8249e8a;

    /// @notice Verify against https://github.com/ethereum-optimism/superchain-registry/blob/21506ecedf6e83410d12c7cc406685ac061a2a74/superchain/configs/mainnet/base.toml#L9
    address constant batchInboxAddress = 0xFf00000000000000000000000000000000008453;

    /// @notice Verify against https://github.com/ethereum-optimism/superchain-registry/blob/21506ecedf6e83410d12c7cc406685ac061a2a74/superchain/configs/mainnet/base.toml#L33
    address constant batchSenderAddress = 0x5050F69a9786F081509234F1a7F4684b5E5b76C9;

    /// @notice Verify against https://github.com/ethereum-optimism/superchain-registry/blob/21506ecedf6e83410d12c7cc406685ac061a2a74/superchain/configs/mainnet/base.toml#L39
    address constant systemConfigOwner = 0x14536667Cd30e52C0b458BaACcB9faDA7046E056;

    /// @notice Verify onchain
    uint256 constant l2GenesisBlockGasLimit = 0xABA9500;

    /// @notice Verify onchain
    uint256 constant gasPriceOracleOverhead = 0;

    /// @notice Verify with `cast call 0x73a79Fab69143498Ed3712e519A88a918e1f4072 "scalar()(bytes32)" --rpc-url https://ethereum-rpc.publicnode.com`. We don't link to
    /// the deploy-config here because it needs to be updated to account for the new way the scalar
    /// is encoded post-ecotone. But we don't want this parameter to change, so we hardcode the
    /// existing value (fetched with the above command) here.
    uint256 constant gasPriceOracleScalar = 0x01000000000000000000000000000000000000000000000000101c12000008dd;

    /// @notice Verify against
    uint256 constant systemConfigStartBlock = 17482144;

    // Verify against the `DisputeGameFactoryProxy` deployment address
    address constant dgfProxy = 0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e;

    GnosisSafe ownerSafe;
    address baseSafe;
    address foundationSafe;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
        ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
        baseSafe = vm.envAddress("COUNCIL_SAFE");
        foundationSafe = vm.envAddress("FOUNDATION_SAFE");

        address[] memory owners = ownerSafe.getOwners();
        // assert there are two signers on the owner safe
        assert(owners.length == 2);
        // assert that they are the expected base and fnd safes
        bool baseSafeFound = false;
        bool foundationSafeFound = false;

        for (uint i = 0; i < owners.length; i++){
            if (owners[i] == baseSafe) {
                baseSafeFound = true;
            }
            if (owners[i] == foundationSafe) {
                foundationSafeFound = true;
            }
        }
        assert(baseSafeFound);
        assert(foundationSafeFound);
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory shouldHaveCodeExceptions = new address[](4);

        shouldHaveCodeExceptions[0] = systemConfigOwner;
        shouldHaveCodeExceptions[1] = batchSenderAddress;
        shouldHaveCodeExceptions[2] = p2pSequencerAddress;
        shouldHaveCodeExceptions[3] = batchInboxAddress;

        return shouldHaveCodeExceptions;
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/mainnet/base.toml
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory addressesToml;

        // Read addresses json
        try vm.readFile(
            string.concat(vm.projectRoot(), "/lib/superchain-registry/superchain/configs/mainnet/base.toml")
        ) returns (string memory data) {
            addressesToml = data;
        } catch {
            revert("Failed to read lib/superchain-registry/superchain/configs/mainnet/base.toml");
        }

        _proxies.L1CrossDomainMessenger = stdToml.readAddress(addressesToml, "$.addresses.L1CrossDomainMessengerProxy");
        _proxies.L1StandardBridge = stdToml.readAddress(addressesToml, "$.addresses.L1StandardBridgeProxy");
        _proxies.OptimismMintableERC20Factory =
            stdToml.readAddress(addressesToml, "$.addresses.OptimismMintableERC20FactoryProxy");
        _proxies.OptimismPortal = stdToml.readAddress(addressesToml, "$.addresses.OptimismPortalProxy");
        _proxies.OptimismPortal2 = stdToml.readAddress(addressesToml, "$.addresses.OptimismPortalProxy");
        _proxies.SystemConfig = stdToml.readAddress(addressesToml, "$.addresses.SystemConfigProxy");
        _proxies.L1ERC721Bridge = stdToml.readAddress(addressesToml, "$.addresses.L1ERC721BridgeProxy");
        _proxies.DisputeGameFactory = dgfProxy;

        // Read superchain.toml
        string memory chainConfig;
        string memory path =
            string.concat("/lib/superchain-registry/superchain/configs/mainnet/superchain.toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        _proxies.ProtocolVersions = stdToml.readAddress(chainConfig, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdToml.readAddress(chainConfig, "$.superchain_config_addr");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](5);
        allowed[0] = address(proxies.OptimismPortal2);
        allowed[1] = address(proxies.SystemConfig);
        allowed[2] = address(ownerSafe);
        allowed[3] = address(baseSafe);
        allowed[4] = address(foundationSafe);
    }

    function _nestedPostCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory) internal view override {
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

        // Assert that only the SystemConfig, OptimismPortal and various safes storage are written to
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
                if (storageAccess.isWrite) {
                    address account = storageAccess.account;
                    require(
                        account == _ownerSafe() || account == baseSafe || account == foundationSafe
                            || account == proxies.SystemConfig || account == proxies.OptimismPortal,
                        "state-000"
                    );
                }
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
        require(ISemver(proxies.DisputeGameFactory).version().eq("1.0.0"), "semver-1000");
    }

    /// @notice Asserts that the SystemConfig is setup correctly
    ///         Assertions are similar to the 006-MCP-L1 upgrade
    function checkSystemConfig() internal view {
        console.log("Running chain assertions on the SystemConfig");

        require(proxies.SystemConfig.code.length != 0, "200");
        require(EIP1967Helper.getImplementation(proxies.SystemConfig).code.length != 0, "201");

        SystemConfig configToCheck = SystemConfig(proxies.SystemConfig);
        require(configToCheck.owner() == systemConfigOwner, "300");
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
        bytes32 l2OutputOracleSlot =
            vm.load(address(configToCheck), bytes32(uint256(keccak256("systemconfig.l2outputoracle")) - 1));
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

        require(portalToCheck.guardian() == optimismPortalGuardian, "6000");
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
