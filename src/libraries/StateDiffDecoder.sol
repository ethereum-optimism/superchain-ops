// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {stdJson} from "forge-std/StdJson.sol";

library StateDiffDecoder {
    using LibString for string;
    using stdJson for string;

    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    struct StateDiff {
        bytes32 slot;
        bytes32 oldValue;
        bytes32 newValue;
    }

    struct DecodedSlot {
        string kind;
        string oldValue; // Decoded stringified value.
        string newValue; // Decoded stringified value.
        string summary;
        string detail;
    }

    struct DecodedStateDiff {
        address who;
        uint256 l2ChainId;
        string contractName;
        StateDiff raw;
        DecodedSlot decoded;
    }

    // Temporary struct used during deduplication.
    struct TempStateChange {
        address who;
        bytes32 slot;
        bytes32 firstOld;
        bytes32 lastNew;
    }

    // Leading underscore because some of the raw keys are reserved words in Solidity, and we need
    // the keys to be ordered alphabetically here for foundry.
    struct JsonStorageLayout {
        string _bytes;
        string _label;
        uint256 _offset;
        string _slot;
        string _type;
    }

    // forgefmt: disable-start
    bytes32 internal constant ERC1967_IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant UNSAFE_BLOCK_SIGNER_SLOT = keccak256("systemconfig.unsafeblocksigner");
    bytes32 internal constant L1_CROSS_DOMAIN_MESSENGER_SLOT = bytes32(uint256(keccak256("systemconfig.l1crossdomainmessenger")) - 1);
    bytes32 internal constant L1_ERC_721_BRIDGE_SLOT = bytes32(uint256(keccak256("systemconfig.l1erc721bridge")) - 1);
    bytes32 internal constant L1_STANDARD_BRIDGE_SLOT = bytes32(uint256(keccak256("systemconfig.l1standardbridge")) - 1);
    bytes32 internal constant OPTIMISM_PORTAL_SLOT = bytes32(uint256(keccak256("systemconfig.optimismportal")) - 1);
    bytes32 internal constant OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT = bytes32(uint256(keccak256("systemconfig.optimismmintableerc20factory")) - 1);
    bytes32 internal constant BATCH_INBOX_SLOT = bytes32(uint256(keccak256("systemconfig.batchinbox")) - 1);
    bytes32 internal constant START_BLOCK_SLOT = bytes32(uint256(keccak256("systemconfig.startBlock")) - 1);
    bytes32 internal constant DISPUTE_GAME_FACTORY_SLOT = bytes32(uint256(keccak256("systemconfig.disputegamefactory")) - 1);
    bytes32 internal constant L2_OUTPUT_ORACLE_SLOT = bytes32(uint256(keccak256("systemconfig.l2outputoracle")) - 1);

    bytes32 internal constant PAUSED_SLOT = bytes32(uint256(keccak256("superchainConfig.paused")) - 1);
    bytes32 internal constant GUARDIAN_SLOT = bytes32(uint256(keccak256("superchainConfig.guardian")) - 1);

    bytes32 internal constant REQUIRED_SLOT = bytes32(uint256(keccak256("protocolversion.required")) - 1);
    bytes32 internal constant RECOMMENDED_SLOT = bytes32(uint256(keccak256("protocolversion.recommended")) - 1);

    bytes32 internal constant GAS_PAYING_TOKEN_SLOT = bytes32(uint256(keccak256("opstack.gaspayingtoken")) - 1);
    bytes32 internal constant GAS_PAYING_TOKEN_NAME_SLOT = bytes32(uint256(keccak256("opstack.gaspayingtokenname")) - 1);
    bytes32 internal constant GAS_PAYING_TOKEN_SYMBOL_SLOT = bytes32(uint256(keccak256("opstack.gaspayingtokensymbol")) - 1);
    // forgefmt: disable-end

    function decode(VmSafe.AccountAccess[] memory _accountAccesses) internal {
        vm.pauseGasMetering();
        // First, determine the maximum possible number of storage writes.
        uint256 maxEntries = 0;
        for (uint256 i = 0; i < _accountAccesses.length; i++) {
            for (uint256 j = 0; j < _accountAccesses[i].storageAccesses.length; j++) {
                VmSafe.StorageAccess memory storageAccess = _accountAccesses[i].storageAccesses[j];
                if (storageAccess.isWrite && storageAccess.previousValue != storageAccess.newValue) {
                    maxEntries++;
                }
            }
        }

        // Allocate a temporary array to deduplicate writes.
        TempStateChange[] memory deduped = new TempStateChange[](maxEntries);
        uint256 dedupCount = 0;

        // Iterate in order so that the first write encountered holds the initial (old) value.
        for (uint256 i = 0; i < _accountAccesses.length; i++) {
            for (uint256 j = 0; j < _accountAccesses[i].storageAccesses.length; j++) {
                VmSafe.StorageAccess memory storageAccess = _accountAccesses[i].storageAccesses[j];

                // Only process writes where the value has actually changed.
                if (storageAccess.isWrite && storageAccess.previousValue != storageAccess.newValue) {
                    bool found = false;

                    // Check if we've already seen this address and slot pair.
                    for (uint256 k = 0; k < dedupCount; k++) {
                        if (deduped[k].who == storageAccess.account && deduped[k].slot == storageAccess.slot) {
                            // Update the new value to the latest value.
                            deduped[k].lastNew = storageAccess.newValue;
                            found = true;
                            break;
                        }
                    }

                    // If not found, record a new change.
                    if (!found) {
                        deduped[dedupCount] = TempStateChange({
                            who: storageAccess.account,
                            slot: storageAccess.slot,
                            firstOld: storageAccess.previousValue,
                            lastNew: storageAccess.newValue
                        });
                        dedupCount++;
                    }
                }
            }
        }

        // Filter out state changes where the first old value equals the final new value.
        DecodedStateDiff[] memory tempStateDiffs = new DecodedStateDiff[](dedupCount);
        uint256 filteredCount = 0;
        for (uint256 i = 0; i < dedupCount; i++) {
            if (deduped[i].firstOld == deduped[i].lastNew) {
                continue;
            }
            address who = deduped[i].who;
            (uint256 l2ChainId, string memory contractName) = getContractInfo(who);
            DecodedSlot memory decoded =
                tryDecode(contractName, deduped[i].slot, deduped[i].firstOld, deduped[i].lastNew);
            tempStateDiffs[filteredCount] = DecodedStateDiff({
                who: who,
                l2ChainId: l2ChainId,
                contractName: contractName,
                raw: StateDiff({slot: deduped[i].slot, oldValue: deduped[i].firstOld, newValue: deduped[i].lastNew}),
                decoded: decoded
            });
            filteredCount++;
        }

        // Create the final array with the exact number of filtered entries.
        DecodedStateDiff[] memory stateDiffs = new DecodedStateDiff[](filteredCount);
        for (uint256 i = 0; i < filteredCount; i++) {
            stateDiffs[i] = tempStateDiffs[i];
        }

        // Lastly, print the decoded state infos.
        for (uint256 i = 0; i < stateDiffs.length; i++) {
            DecodedStateDiff memory state = stateDiffs[i];
            console.log("\n----- DecodedStateDiff[%s] -----", i);
            console.log("Who:               %s", state.who);
            console.log("Contract:          %s", state.contractName);
            console.log("Chain ID:          %s", state.l2ChainId == 0 ? "" : vm.toString(state.l2ChainId));
            console.log("Raw Slot:          %s", vm.toString(state.raw.slot));
            console.log("Raw Old Value:     %s", vm.toString(state.raw.oldValue));
            console.log("Raw New Value:     %s", vm.toString(state.raw.newValue));

            // Check if decoded.kind is empty.
            if (bytes(state.decoded.kind).length == 0) {
                console.log("\x1B[33m[WARN]\x1B[0m Slot was not decoded");
            } else {
                console.log("Decoded Kind:      %s", state.decoded.kind);
                console.log("Decoded Old Value: %s", state.decoded.oldValue);
                console.log("Decoded New Value: %s", state.decoded.newValue);
                console.log("Summary:           %s", state.decoded.summary);
                console.log("Detail:            %s", state.decoded.detail);
            }
        }
        vm.resumeGasMetering();
    }

    function getContractInfo(address _address)
        internal
        view
        returns (uint256 l2ChainId_, string memory contractName_)
    {
        string memory addrsPath = "/lib/superchain-registry/superchain/extra/addresses/addresses.json";
        string memory path = string.concat(vm.projectRoot(), addrsPath);
        return findContractByAddress(path, _address);
    }

    /// @notice Attempts to decode a storage slot.
    function tryDecode(string memory _contractName, bytes32 _slot, bytes32 _oldValue, bytes32 _newValue)
        internal
        view
        returns (DecodedSlot memory decoded_)
    {
        decoded_ = tryUnstructuredSlot(_slot, _oldValue, _newValue);
        if (bytes(decoded_.kind).length > 0) return decoded_;

        // If the contract name is empty, we cannot attempt further decoding.
        if (bytes(_contractName).length == 0) return decoded_;

        return tryStorageLayoutLookup(_contractName, _slot, _oldValue, _newValue);
    }

    /// @notice Checks if the slot is a known unstructured slot and returns the decoded slot if so.
    /// The caller must verify that `decoded.kind` is not empty to confirm decoding.
    function tryUnstructuredSlot(bytes32 _slot, bytes32 _oldValue, bytes32 _newValue)
        internal
        pure
        returns (DecodedSlot memory decoded_)
    {
        // ERC-1967.
        if (_slot == ERC1967_IMPL_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "ERC-1967 implementation slot",
                detail: "Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard."
            });
        }

        // SystemConfig.
        if (_slot == UNSAFE_BLOCK_SIGNER_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "Unsafe block signer address",
                detail: "Unstructured storage slot for the address of the account which authenticates the unsafe/pre-submitted blocks for a chain at the P2P layer."
            });
        }
        if (_slot == L1_CROSS_DOMAIN_MESSENGER_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "L1CrossDomainMessenger proxy address",
                detail: "Unstructured storage slot for the address of the L1CrossDomainMessenger proxy."
            });
        }
        if (_slot == L1_ERC_721_BRIDGE_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "L1ERC721Bridge proxy address",
                detail: "Unstructured storage slot for the address of the L1ERC721Bridge proxy."
            });
        }
        if (_slot == L1_STANDARD_BRIDGE_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "L1StandardBridge proxy address",
                detail: "Unstructured storage slot for the address of the L1StandardBridge proxy."
            });
        }
        if (_slot == OPTIMISM_PORTAL_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "OptimismPortal proxy address",
                detail: "Unstructured storage slot for the address of the OptimismPortal proxy."
            });
        }
        if (_slot == OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "OptimismMintableERC20Factory proxy address",
                detail: "Unstructured storage slot for the address of the OptimismMintableERC20Factory proxy."
            });
        }
        if (_slot == BATCH_INBOX_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "Batch inbox address",
                detail: "Unstructured storage slot for the address of the BatchInbox proxy."
            });
        }
        if (_slot == START_BLOCK_SLOT) {
            return DecodedSlot({
                kind: "uint256",
                oldValue: toUint(_oldValue),
                newValue: toUint(_newValue),
                summary: "Start block",
                detail: "Unstructured storage slot for the start block number."
            });
        }
        if (_slot == DISPUTE_GAME_FACTORY_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "DisputeGameFactory proxy address",
                detail: "Unstructured storage slot for the address of the DisputeGameFactory proxy."
            });
        }
        if (_slot == L2_OUTPUT_ORACLE_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "L2OutputOracle proxy address",
                detail: "Unstructured storage slot for the address of the L2OutputOracle proxy."
            });
        }

        // SuperchainConfig.
        if (_slot == PAUSED_SLOT) {
            return DecodedSlot({
                kind: "bool",
                oldValue: toBool(_oldValue),
                newValue: toBool(_newValue),
                summary: "Superchain pause status",
                detail: "Unstructured storage slot for the pause status of the superchain."
            });
        }
        if (_slot == GUARDIAN_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "Guardian address",
                detail: "Unstructured storage slot for the address of the superchain guardian."
            });
        }

        // ProtocolVersions.
        if (_slot == REQUIRED_SLOT) {
            return DecodedSlot({
                kind: "uint256",
                oldValue: toUint(_oldValue),
                newValue: toUint(_newValue),
                summary: "Required protocol version",
                detail: "Unstructured storage slot for the required protocol version."
            });
        }
        if (_slot == RECOMMENDED_SLOT) {
            return DecodedSlot({
                kind: "uint256",
                oldValue: toUint(_oldValue),
                newValue: toUint(_newValue),
                summary: "Recommended protocol version",
                detail: "Unstructured storage slot for the recommended protocol version."
            });
        }

        // Gas paying token slots.
        if (_slot == GAS_PAYING_TOKEN_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "Gas paying token address",
                detail: "Unstructured storage slot for the address of the gas paying token."
            });
        }
        if (_slot == GAS_PAYING_TOKEN_NAME_SLOT) {
            return DecodedSlot({
                kind: "string",
                oldValue: vm.toString(_oldValue),
                newValue: vm.toString(_newValue),
                summary: "Gas paying token name",
                detail: "Unstructured storage slot for the name of the gas paying token."
            });
        }
        if (_slot == GAS_PAYING_TOKEN_SYMBOL_SLOT) {
            return DecodedSlot({
                kind: "string",
                oldValue: vm.toString(_oldValue),
                newValue: vm.toString(_newValue),
                summary: "Gas paying token symbol",
                detail: "Unstructured storage slot for the symbol of the gas paying token."
            });
        }
    }

    /// @notice Given a contract name and a slot, looks up the storage layout for the contract and
    /// returns the decoded slot if it is found.
    function tryStorageLayoutLookup(string memory _contractName, bytes32 _slot, bytes32 _oldValue, bytes32 _newValue)
        internal
        view
        returns (DecodedSlot memory decoded_)
    {
        // Lookup the storage layout for the contract.
        // TODO: For now this just uses the submodule's version of the monorepo. A future improvement
        // would be to look up the latest release from the registry and fetch the storage layout
        // from the monorepo at that tag.
        string memory basePath = "/lib/optimism/packages/contracts-bedrock/snapshots/storageLayout/";
        string memory artifactName = _contractName.endsWith("(GnosisSafe)") ? "GnosisSafe" : _contractName;
        string memory path = string.concat(vm.projectRoot(), basePath, artifactName, ".json");

        string memory storageLayout;
        try vm.readFile(path) returns (string memory result) {
            storageLayout = result;
        } catch {
            console.log("\x1B[33m[WARN]\x1B[0m Failed to read storage layout file at %s", path);
            return DecodedSlot({kind: "", oldValue: "", newValue: "", summary: "", detail: ""});
        }
        bytes memory parsedStorageLayout = vm.parseJson(storageLayout, "$");
        JsonStorageLayout[] memory layout = abi.decode(parsedStorageLayout, (JsonStorageLayout[]));

        // Iterate over the storage layout and look for the slot.
        for (uint256 i = 0; i < layout.length; i++) {
            if (vm.parseUint(layout[i]._slot) == uint256(_slot)) {
                // Decode the 32-byte value based on the size and offset of the slot.
                string memory kind = layout[i]._type;
                uint256 offset = layout[i]._offset;
                string memory oldValue;
                string memory newValue;
                if (kind.eq("bool")) {
                    oldValue = toBool(_oldValue, offset);
                    newValue = toBool(_newValue, offset);
                } else if (kind.eq("address")) {
                    oldValue = toAddress(_oldValue, offset);
                    newValue = toAddress(_newValue, offset);
                } else if (kind.contains("uint")) {
                    oldValue = toUint(_oldValue, offset);
                    newValue = toUint(_newValue, offset);
                }

                string memory label = layout[i]._label;
                return DecodedSlot({kind: kind, oldValue: oldValue, newValue: newValue, summary: label, detail: ""});
            }
        }
    }

    /// @notice Given the path to a JSON file and a target address, returns the first chain ID and
    /// contract name where the value equals the target.
    function findContractByAddress(string memory filePath, address target)
        internal
        view
        returns (uint256 l2ChainId_, string memory contractName_)
    {
        // Read the entire JSON file.
        string memory jsonData = vm.readFile(filePath);

        // Get all the top-level keys, which are the chain IDs
        string[] memory chainIds = vm.parseJsonKeys(jsonData, "$");
        for (uint256 i = 0; i < chainIds.length; i++) {
            string memory chainId = chainIds[i];

            // Get all the keys of the nested object under currentTopKey.
            string memory key = string.concat("$.", chainId);
            string[] memory contractNames = vm.parseJsonKeys(jsonData, key);
            for (uint256 j = 0; j < contractNames.length; j++) {
                string memory contractName = contractNames[j];

                // Build the JSON path: e.g. ".10.Guardian"
                string memory path = string.concat(".", chainId, ".", contractName);
                address foundAddress = vm.parseJsonAddress(jsonData, path);

                if (foundAddress == target) {
                    // If the contract name ends with "Proxy", strip it.
                    if (contractName.endsWith("Proxy")) {
                        contractName = contractName.slice(0, bytes(contractName).length - 5);
                    }
                    // If the contract name is "OptimismPortal", change it to "OptimismPortal2".
                    if (contractName.eq("OptimismPortal")) {
                        contractName = "OptimismPortal2";
                    }
                    // We make a call to see if the contract is a Safe.
                    if (isGnosisSafe(target)) {
                        contractName = string.concat(contractName, " (GnosisSafe)");
                    }

                    return (vm.parseUint(chainId), contractName);
                }
            }
        }

        // If we get here, the address was not found in the registry. We check for other kinds of
        // known contracts.
        if (isGnosisSafe(target)) return (0, "Unknown (GnosisSafe)");
        if (isLivenessGuard(target)) return (0, "LivenessGuard");
        if (isLivenessModule(target)) return (0, "LivenessModule");

        console.log("\x1B[33m[WARN]\x1B[0m Target address not found: %s", vm.toString(target));
        return (0, "");
    }

    /// @notice Probabilistically check if an address is a GnosisSafe.
    function isGnosisSafe(address _who) internal view returns (bool) {
        bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("getThreshold()")));
        (bool ok, bytes memory data) = _who.staticcall(callData);
        return ok && data.length == 32;
    }

    /// @notice Probabilistically check if an address is a LivenessGuard.
    function isLivenessGuard(address _who) internal view returns (bool) {
        bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("lastLive(address)")), address(0));
        (bool ok, bytes memory data) = _who.staticcall(callData);
        return ok && data.length == 32;
    }

    /// @notice Probabilistically check if an address is a LivenessModule.
    function isLivenessModule(address _who) internal view returns (bool) {
        bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("ownershipTransferredToFallback()")));
        (bool ok, bytes memory data) = _who.staticcall(callData);
        return ok && data.length == 32;
    }

    function toBool(bytes32 _value) internal pure returns (string memory) {
        return toBool(_value, 0);
    }

    function toBool(bytes32 _value, uint256 _offset) internal pure returns (string memory) {
        bool x = (uint256(_value) >> (_offset * 8)) == 1;
        return x ? "true" : "false";
    }

    function toAddress(bytes32 _value) internal pure returns (string memory) {
        return toAddress(_value, 0);
    }

    function toAddress(bytes32 _value, uint256 _offset) internal pure returns (string memory) {
        return vm.toString(address(uint160(uint256(_value) >> (_offset * 8))));
    }

    function toUint(bytes32 _value) internal pure returns (string memory) {
        return toUint(_value, 0);
    }

    function toUint(bytes32 _value, uint256 _offset) internal pure returns (string memory) {
        return vm.toString(uint256(_value) >> (_offset * 8));
    }
}
