// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VmSafe} from "forge-std/Vm.sol";
import {Script} from "forge-std/Script.sol";

import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {AddressManager} from "@eth-optimism-bedrock/src/legacy/AddressManager.sol";
import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {OptimismPortal} from "@eth-optimism-bedrock/src/L1/OptimismPortal.sol";
import {L1CrossDomainMessenger} from "@eth-optimism-bedrock/src/L1/L1CrossDomainMessenger.sol";
import {L2OutputOracle} from "@eth-optimism-bedrock/src/L1/L2OutputOracle.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";
import {ProtocolVersions} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";

/// @title SuperchainRegistryStorage
/// @dev This contract is just a reusable storage layout for holding all of the important contracts across a given
///      superchain.
abstract contract SuperchainRegistryStorage {
    struct L1PerChainContracts {
        OptimismPortal portalProxy;
        L1CrossDomainMessenger messengerProxy;
        L1StandardBridge bridgeProxy;
        L1ERC721Bridge erc721BridgeProxy;
        L2OutputOracle outputOracleProxy;
        ProxyAdmin proxyAdmin;
        AddressManager addressManager;
        OptimismMintableERC20Factory erc20Factory;
        SystemConfig systemConfigProxy;
    }

    struct L1SingletonContracts {
        SuperchainConfig superchainConfigsProxy;
        ProtocolVersions protocolVersionsProxy;
    }

    // List of paths to json files in the superchain-registry repo
    string[] public chainPaths;

    // Mapping to retrieve the contracts for each chain
    // Can be used along with the chainPaths array like an enumerable set to retrieve the contracts for each chain
    mapping(string => L1PerChainContracts) public perChainContracts;

    // Singleton contracts
    L1SingletonContracts public singletonContracts;
}

/// @title LibSuperchainRegistry
/// @dev A library to for reading the superchain-registry repo
library LibSuperchainRegistry {
    VmSafe constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @dev Takes the path to a file in the superchain-registry repo and returns the chain name.
    function _getChainNameFromFile(string memory _path) internal view returns (string memory) {
        (bool success, bytes memory splitData) =
            address(vm).staticcall(abi.encodeWithSignature("split(string,string)", _path, "/"));
        require(success, "Failed string split");
        string[] memory pathArray = abi.decode(splitData, (string[]));
        string memory baseName = pathArray[pathArray.length - 1];

        (bool success2, bytes memory replaceData) =
            address(vm).staticcall(abi.encodeWithSignature("replace(string,string,string)", baseName, ".json", ""));
        require(success2, "Failed string split");

        string memory name = string(replaceData);
        return name;
    }

    /// @dev Looks up the address of a contract on a given chain in the superhcain-registry repo
    function _getChainAddresses(string memory _path, string memory _contractName) internal returns (address) {
        string[] memory commands = new string[](3);
        commands[0] = "bash";
        commands[1] = "-c";
        commands[2] = string.concat("jq -cr . < ", _path);
        string memory json = string(vm.ffi(commands));

        address addr = stdJson.readAddress(json, string.concat("$.", _contractName));

        console.log(string.concat("Address for ", _contractName, " on ", _getChainNameFromFile(_path), " is "), addr);
        return addr;
    }
}

/// @title SuperchainRegistryScript
/// @notice Template script useful for quickly setting up an exploit against the L1 contracts. In order to get the
///         addresses of the contracts:
///         1. forge install --no-git ethereum-optimism/superchain-registry
///         2. forge script SuperchainRegistryScript -vv --ffi
contract SuperchainRegistryScript is SuperchainRegistryStorage, Script {
    SuperchainRegistryOperation public operationContract;

    /// @dev Retrieves the paths to the chain specific files (ie. op.json) from the superchain-registry.
    function _populateChainPaths() internal {
        string memory path = "lib/superchain-registry/superchain/extra/addresses/mainnet/";
        VmSafe.DirEntry[] memory chainFiles = vm.readDir(path);
        for (uint256 i = 0; i < chainFiles.length; i++) {
            chainPaths.push(chainFiles[i].path);
        }
    }

    /// @dev Populates the perChainContracts mapping with the contracts for each chain
    function _populatePerChainContracts() internal {
        for (uint256 i = 0; i < chainPaths.length; i++) {
            string memory chain = chainPaths[i];
            L1PerChainContracts memory contracts;
            contracts.portalProxy =
                OptimismPortal(payable(LibSuperchainRegistry._getChainAddresses(chain, "OptimismPortalProxy")));
            contracts.messengerProxy = L1CrossDomainMessenger(
                payable(LibSuperchainRegistry._getChainAddresses(chain, "L1CrossDomainMessengerProxy"))
            );
            contracts.bridgeProxy =
                L1StandardBridge(payable(LibSuperchainRegistry._getChainAddresses(chain, "L1StandardBridgeProxy")));
            contracts.erc721BridgeProxy =
                L1ERC721Bridge(LibSuperchainRegistry._getChainAddresses(chain, "L1ERC721BridgeProxy"));
            contracts.outputOracleProxy =
                L2OutputOracle(LibSuperchainRegistry._getChainAddresses(chain, "L2OutputOracleProxy"));
            contracts.proxyAdmin = ProxyAdmin(payable(LibSuperchainRegistry._getChainAddresses(chain, "ProxyAdmin")));
            contracts.addressManager = AddressManager(LibSuperchainRegistry._getChainAddresses(chain, "AddressManager"));
            contracts.erc20Factory = OptimismMintableERC20Factory(
                LibSuperchainRegistry._getChainAddresses(chain, "OptimismMintableERC20FactoryProxy")
            );
            contracts.systemConfigProxy =
                SystemConfig(LibSuperchainRegistry._getChainAddresses(chain, "SystemConfigProxy"));
            perChainContracts[chain] = contracts;
        }
    }

    function _populateSingletonContracts() internal {
        // Set the singleton contracts
        // We do this manually because they are unlikely to change, and stored in yaml files which I don't know how to
        // parse in a forge script.
        singletonContracts.superchainConfigsProxy = SuperchainConfig(0x95703e0982140D16f8ebA6d158FccEde42f04a4C);
        singletonContracts.protocolVersionsProxy = ProtocolVersions(0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935);
    }

    function run() public {
        _populateChainPaths();
        _populatePerChainContracts();
        _populateSingletonContracts();
        L1PerChainContracts[] memory perChainContractsArray = new L1PerChainContracts[](chainPaths.length);
        for (uint256 i = 0; i < chainPaths.length; i++) {
            perChainContractsArray[i] = perChainContracts[chainPaths[i]];
        }

        vm.startBroadcast();
        operationContract = new SuperchainRegistryOperation{value: (1) * chainPaths.length}({
            _chainPaths: chainPaths,
            _chainContracts: perChainContractsArray,
            _singletonContracts: singletonContracts
        });
        vm.stopBroadcast();
    }
}

/// @dev A contract deployed by the SuperchainRegistryScript to perform an on-chain operation. As an example we will
///      make a deposit of 1 ETH into each of the the L1StandardBridge contracts. For other operations, it should be
///      as simple as modifying the performOperation function.
contract SuperchainRegistryOperation is SuperchainRegistryStorage {
    constructor(
        string[] memory _chainPaths,
        L1PerChainContracts[] memory _chainContracts,
        L1SingletonContracts memory _singletonContracts
    ) payable {
        // Populate storage again in the exploit contract
        chainPaths = _chainPaths;
        for (uint256 i = 0; i < _chainPaths.length; i++) {
            perChainContracts[_chainPaths[i]] = _chainContracts[i];
        }
        singletonContracts = _singletonContracts;

        performOperation();
    }

    /// @dev An internal function to perform the deposit. This function is called by the constructor in order to
    ///      perform the operation atomically.
    function performOperation() internal {
        uint256 value = 1;

        uint256 numChains = chainPaths.length;
        require(address(this).balance >= numChains * value, "Not enough ETH to deposit");

        // For example, if we wanted to deposit 1 wei into each bridge, we would do the following:
        for (uint256 i = 0; i < chainPaths.length; i++) {
            L1StandardBridge bridge = perChainContracts[chainPaths[i]].bridgeProxy;
            OptimismPortal portal = perChainContracts[chainPaths[i]].portalProxy;
            uint256 portalBalanceBefore = address(portal).balance;
            uint256 senderBalanceBefore = address(this).balance;

            // your operation here:
            (bool success,) = address(bridge).call{value: value}("");
            require(success, "Deposit failed");

            // Make sure the deposit worked for each bridge:
            require(address(this).balance == senderBalanceBefore - value, "Sender balance not decreased");
            require(address(portal).balance == portalBalanceBefore + value, "Portal balance not increased");
        }
    }
}
