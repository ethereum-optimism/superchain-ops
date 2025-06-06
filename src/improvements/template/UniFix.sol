// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IStandardValidatorV180} from "@eth-optimism-bedrock/interfaces/L1/IStandardValidator.sol";
import {
    IOptimismPortal2,
    IProxyAdmin,
    ISuperchainConfig,
    IDisputeGameFactory,
    IFaultDisputeGame,
    GameType,
    Claim
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {StorageSetter} from "@eth-optimism-bedrock/src/universal/StorageSetter.sol";
import {LibString} from "solady/utils/LibString.sol";

import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {AddressRegistry} from "src/improvements/tasks/MultisigTask.sol";
import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template contract for configuring protocol parameters.
///         This file is intentionally stripped down; please add your logic where indicated.
///         Please make sure to address all TODOs and remove the require() statements.
contract UniFix is L2TaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice The StandardValidatorV180 address
    IStandardValidatorV180 public STANDARD_VALIDATOR_V180;

    IProxyAdmin public proxyAdmin;
    ISuperchainConfig public superchainConfig;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](8);
        storageWrites[0] = "L1CrossDomainMessengerProxy";
        storageWrites[1] = "AddressManager";
        storageWrites[2] = "L1ERC721BridgeProxy";
        storageWrites[3] = "L1StandardBridgeProxy";
        storageWrites[4] = "OptimismPortalProxy";
        storageWrites[5] = "AnchorStateRegistryProxy";
        storageWrites[6] = "PermissionedWETH"; // GameType 1
        storageWrites[7] = "PermissionlessWETH"; // GameType 0

        return storageWrites;
    }

    function _configureTask(string memory configPath)
        internal
        override
        returns (AddressRegistry addrRegistry_, IGnosisSafe parentMultisig_, address multicallTarget_)
    {
        (addrRegistry_, parentMultisig_, multicallTarget_) = super._configureTask(configPath);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        assertEq(chains.length, 1);
        assertEq(chains[0].chainId, 1301);

        // Get the SuperchainConfig address for Op Sepolia.
        // https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/extra/addresses/addresses.json#L64
        IOptimismPortal2 opSepoliaOptimismPortal = IOptimismPortal2(payable(0x16Fc5058F25648194471939df75CF27A2fdC48BC));
        superchainConfig = ISuperchainConfig(opSepoliaOptimismPortal.superchainConfig());

        // Get the ProxyAdmin address for Uni Sepolia.
        proxyAdmin = IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", 1301));

        string memory tomlContent = vm.readFile(taskConfigFilePath);
        STANDARD_VALIDATOR_V180 = IStandardValidatorV180(tomlContent.readAddress(".addresses.StandardValidatorV180"));
        require(STANDARD_VALIDATOR_V180.disputeGameFactoryVersion().eq("1.0.0"), "Incorrect StandardValidatorV180");
        vm.label(address(STANDARD_VALIDATOR_V180), "StandardValidatorV180");
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        // We are only operating on Uni Sepolia.
        assertEq(chains.length, 1);
        assertEq(chains[0].chainId, 1301);

        // Get the addresses for Uni Sepolia.
        address l1CrossDomainMessengerProxy = superchainAddrRegistry.getAddress("L1CrossDomainMessengerProxy", 1301);
        address l1ERC721BridgeProxy = superchainAddrRegistry.getAddress("L1ERC721BridgeProxy", 1301);
        address l1StandardBridgeProxy = superchainAddrRegistry.getAddress("L1StandardBridgeProxy", 1301);
        address optimismPortalProxy = superchainAddrRegistry.getAddress("OptimismPortalProxy", 1301);
        address anchorStateRegistryProxy = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", 1301);

        // These are wrong in the registry, I queried them directly from the chain.
        address delayedWETHPermissioned = 0x73D18d6Caa14AeEc15449d0A25A31D4e7E097a5c;
        address delayedWETHPermissionless = 0x4E7e6dC46CE003A1E353B6848BF5a4fc1FeAC8Ae;

        bytes32 superchainConfigSlotValue = bytes32(uint256(uint160(address(superchainConfig))));

        // https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L132
        _writeToProxy(l1CrossDomainMessengerProxy, bytes32(uint256(251)), superchainConfigSlotValue);

        //https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L55
        _writeToProxy(l1ERC721BridgeProxy, bytes32(uint256(50)), superchainConfigSlotValue);

        // https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L62
        _writeToProxy(l1StandardBridgeProxy, bytes32(uint256(50)), superchainConfigSlotValue);

        // https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/AnchorStateRegistry.json#L27
        _writeToProxy(anchorStateRegistryProxy, bytes32(uint256(2)), superchainConfigSlotValue);

        // https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/DelayedWETH.json#L62
        _writeToProxy(delayedWETHPermissioned, bytes32(uint256(104)), superchainConfigSlotValue);
        _writeToProxy(delayedWETHPermissionless, bytes32(uint256(104)), superchainConfigSlotValue);

        // https://github.com/ethereum-optimism/optimism/blob/2073f4059bd806af3e8b76b820aa3fa0b42016d0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L61-L62
        bytes32 superchainConfigSlotValueWithSpacer = bytes32(uint256(uint160(address(superchainConfig))) << 8);
        _writeToProxy(optimismPortalProxy, bytes32(uint256(53)), superchainConfigSlotValueWithSpacer);
    }

    /// @notice Writes a value to a proxy contract.
    /// @dev This is accomplished by upgrading the proxy to the StorageSetter, writing the value,
    /// and then upgrading the proxy back to the previous implementation.
    /// @param proxy The address of the proxy contract.
    /// @param slot The slot to write to.
    /// @param value The value to write.
    function _writeToProxy(address proxy, bytes32 slot, bytes32 value) internal {
        address storageSetter = 0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC;

        // Upgrade the proxy to the StorageSetter.
        address implBefore = proxyAdmin.getProxyImplementation(proxy);
        proxyAdmin.upgrade(payable(proxy), storageSetter);

        StorageSetter(proxy).setBytes32(slot, value);
        proxyAdmin.upgrade(payable(proxy), implBefore);
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        assertEq(chains.length, 1);
        assertEq(chains[0].chainId, 1301);

        uint256 chainId = chains[0].chainId;
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));
        bytes32 currentAbsolutePrestate =
            Claim.unwrap(IFaultDisputeGame(address(disputeGameFactory.gameImpls(GameType.wrap(1)))).absolutePrestate());

        address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

        IStandardValidatorV180.InputV180 memory input = IStandardValidatorV180.InputV180({
            proxyAdmin: address(proxyAdmin),
            sysCfg: sysCfg,
            absolutePrestate: currentAbsolutePrestate,
            l2ChainID: chainId
        });

        string memory reasons = STANDARD_VALIDATOR_V180.validate({_input: input, _allowFailure: true});
        // "PROXYA-10", // Proxy admin owner must be l1PAOMultisig - This is OK because it is checking for the OP Sepolia PAO
        // "SYSCON-20", // System config gas limit must be 60,000,000 - This is OK because we don't touch the system config
        // "DF-30", // Dispute factory owner must be l1PAOMultisig - It is checking for the OP Sepolia PAO
        // "PDDG-DWETH-30", // Delayed WETH owner must be l1PAOMultisig (for permissioned dispute game) - It is checking for the OP Sepolia PAO
        // "PDDG-ANCHORP-40", // Anchor state registry root must match expected dead root (for permissioned dispute game) - This does not apply to any chain more than 1 week old
        // "PDDG-120", // Permissioned dispute game challenger must match challenger address - It is checking for the OP Sepolia Challenger
        // "PLDG-DWETH-30", // Delayed WETH owner must be l1PAOMultisig (for permissionless dispute game) - It is checking for the OP Sepolia PAO
        // "PLDG-ANCHORP-40" // Anchor state registry root must match expected dead root (for permissionless dispute game) - This does not apply to any chain more than 1 week old
        string memory expectedErrors_1310 =
            "PROXYA-10,SYSCON-20,DF-30,PDDG-DWETH-30,PDDG-ANCHORP-40,PDDG-120,PLDG-DWETH-30,PLDG-ANCHORP-40";

        require(reasons.eq(expectedErrors_1310), string.concat("Unexpected errors: ", reasons));
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal pure override returns (address[] memory) {
        return new address[](0);
    }
}
