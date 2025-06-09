// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {StdStyle} from "forge-std/StdStyle.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Utils} from "src/libraries/Utils.sol";

/// @notice Parses account accesses into decoded transfers and state diffs.
/// The core methods intended to be part of the public interface are `decodeAndPrint`, `decode`,
/// `getUniqueWrites`, `getStateDiffFor`, and `normalizedStateDiffHash`. Example usage:
///
/// ```solidity
/// contract MyContract {
///     using AccountAccessParser for VmSafe.AccountAccess[];
///
///     function myFunction(VmSafe.AccountAccess[] memory accountAccesses) public {
///         // Decode all state changes and ETH/ERC20 transfers and print to the terminal.
///         accountAccesses.decodeAndPrint();
///
///         // Get all decoded data without printing.
///         (
///             AccountAccessParser.DecodedTransfer[] memory transfers,
///             AccountAccessParser.DecodedStateDiff[] memory diffs
///         ) = accountAccesses.decode(false);
///
///         // Get the state diff for a given account.
///         StateDiff[] memory diffs = accountAccesses.getStateDiffFor(myContract, false);
///
///         // Get an array of all unique accounts that had state changes.
///         address[] memory accountsWithStateChanges = accountAccesses.getUniqueWrites(false);
///
///         // Get all new contracts created.
///         address[] memory newContracts = accountAccesses.getNewContracts();
///
///         // Get the normalized state diff hash.
///         bytes32 normalizedStateDiffHash = accountAccesses.normalizedStateDiffHash(parentMultisig, txHash);
///     }
/// }
/// ```
library AccountAccessParser {
    using LibString for string;
    using stdJson for string;
    using StdStyle for string;

    address internal constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant ZERO = address(0);
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    /// It's possible for there to be more state changes than number of accesses. We choose an arbitarily large number
    /// to ensure we have enough space to capture all state changes for any given access trace. If we exceed this limit,
    /// the code will: panic: array out-of-bounds access.
    uint256 internal constant MAX_STATE_CHANGES = 1000;

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

    struct DecodedTransfer {
        address from;
        address to;
        uint256 value;
        address tokenAddress;
    }

    // This struct represents a state change with the account information
    struct AccountStateDiff {
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
    bytes32 internal constant ERC1967_IMPL_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    bytes32 internal constant PROXY_OWNER_ADDR_SLOT = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);

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

    bytes32 internal constant GNOSIS_SAFE_NONCE_SLOT = bytes32(uint256(5));
    bytes32 internal constant GNOSIS_SAFE_APPROVE_HASHES_SLOT = bytes32(uint256(8));

    bytes32 internal constant LIVENESS_GUARD_LAST_LIVE_SLOT = bytes32(uint256(0));

    bytes32 internal constant ANCHOR_STATE_REGISTRY_RETIREMENT_TIMESTAMP_SLOT = bytes32(uint256(6));
    bytes32 internal constant ANCHOR_STATE_REGISTRY_PROPOSAL_ROOT_SLOT = bytes32(uint256(3));
    bytes32 internal constant ANCHOR_STATE_REGISTRY_PROPOSAL_L2_SEQUENCE_NUMBER_SLOT = bytes32(uint256(4));

    bytes32 internal constant OPTIMISM_PORTAL_RESOURCE_PARAMS_SLOT = bytes32(uint256(1));

    // forgefmt: disable-end

    modifier noGasMetering() {
        // We use low-level staticcalls so we can keep cheatcodes as view functions.
        (bool ok,) = address(vm).staticcall(abi.encodeWithSelector(VmSafe.pauseGasMetering.selector));
        require(ok, "pauseGasMetering failed");

        _;

        (ok,) = address(vm).staticcall(abi.encodeWithSelector(VmSafe.resumeGasMetering.selector));
        require(ok, "resumeGasMetering failed");
    }

    // ==============================================================
    // ======== Methods intended to be used as the interface ========
    // ==============================================================

    /// @notice Convenience function that wraps decode and print together.
    function decodeAndPrint(VmSafe.AccountAccess[] memory _accesses, address _parentMultisig, bytes32 _txHash)
        internal
        view
    {
        // We always want to sort all state diffs before printing them.
        (DecodedTransfer[] memory transfers, DecodedStateDiff[] memory stateDiffs) = decode(_accesses, true);
        if (!Utils.isFeatureEnabled("SIGNING_MODE_IN_PROGRESS")) {
            print(transfers, stateDiffs, _parentMultisig, _txHash);
        }
    }

    /// @notice Decodes the provided AccountAccess array into decoded transfers and state diffs.
    function decode(VmSafe.AccountAccess[] memory _accountAccesses, bool _sort)
        internal
        view
        noGasMetering
        returns (DecodedTransfer[] memory transfers, DecodedStateDiff[] memory stateDiffs)
    {
        // --- Transfers ---
        // Allocate a temporary transfers array with maximum possible size (2 transfers per access).
        uint256 n = _accountAccesses.length;
        DecodedTransfer[] memory tempTransfers = new DecodedTransfer[](2 * n);
        uint256 transferIndex = 0;
        // Process each account access once for both ETH and ERC20 transfers.
        for (uint256 i = 0; i < n; i++) {
            DecodedTransfer memory ethTransfer = getETHTransfer(_accountAccesses[i]);
            if (ethTransfer.value != 0) {
                tempTransfers[transferIndex] = ethTransfer;
                transferIndex++;
            }

            DecodedTransfer memory erc20Transfer = getERC20Transfer(_accountAccesses[i]);
            if (erc20Transfer.value != 0) {
                tempTransfers[transferIndex] = erc20Transfer;
                transferIndex++;
            }
        }

        // Copy the valid transfers into an array of the correct length.
        transfers = new DecodedTransfer[](transferIndex);
        for (uint256 i = 0; i < transferIndex; i++) {
            transfers[i] = tempTransfers[i];
        }

        // --- State diffs ---
        // The order of 'uniqueAccounts' informs the order that the account state diffs get processed.
        address[] memory uniqueAccounts = getUniqueWrites(_accountAccesses, _sort);
        uint256 totalDiffCount = 0;
        // Count the total number of net state diffs.
        for (uint256 i = 0; i < uniqueAccounts.length; i++) {
            StateDiff[] memory accountDiffs = getStateDiffFor(_accountAccesses, uniqueAccounts[i], false); // no need to sort here
            totalDiffCount += accountDiffs.length;
        }

        // Aggregate all the diffs and decode each one.
        stateDiffs = new DecodedStateDiff[](totalDiffCount);
        uint256 index = 0;
        for (uint256 i = 0; i < uniqueAccounts.length; i++) {
            StateDiff[] memory accountDiffs = getStateDiffFor(_accountAccesses, uniqueAccounts[i], _sort);
            for (uint256 j = 0; j < accountDiffs.length; j++) {
                address who = uniqueAccounts[i];
                (uint256 l2ChainId, string memory contractName) = getContractInfo(who);
                DecodedSlot memory decoded =
                    tryDecode(contractName, accountDiffs[j].slot, accountDiffs[j].oldValue, accountDiffs[j].newValue);
                stateDiffs[index] = DecodedStateDiff({
                    who: who,
                    l2ChainId: l2ChainId,
                    contractName: contractName,
                    raw: accountDiffs[j],
                    decoded: decoded
                });
                index++;
            }
        }
    }

    /// @notice Extracts all unique contract creations from the provided account accesses.
    function getNewContracts(VmSafe.AccountAccess[] memory accesses)
        internal
        pure
        returns (address[] memory newContracts)
    {
        // Temporary array sized to maximum possible length
        address[] memory temp = new address[](accesses.length);
        uint256 count = 0;

        for (uint256 i = 0; i < accesses.length; i++) {
            // Check if this access is a contract creation
            if (accesses[i].kind == VmSafe.AccountAccessKind.Create && !accesses[i].reverted) {
                // Add the account to our list if it's a successful contract creation
                temp[count] = accesses[i].account;
                count++;
            }
        }

        // Copy the valid contracts into an array of the correct length
        newContracts = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            newContracts[i] = temp[i];
        }
    }

    /// @notice Computes a hash of the normalized state diff from account accesses. The spec for
    /// method is:
    ///   1. The input is an array of `VmSafe.AccountAccess[]` containing all storage writes.
    ///   2. It calls `AccountAccessParser.getUniqueWrites` to filter down all storage writes to a state diff
    ///   3. With that state diff, we normalize it by removing data from the state diff array that
    ///      may change between initial simulation and execution. Removal is done by simply removing
    ///      the entry from the `AccountAccess[]` array. The set of state changes to remove is:
    ///       1. If the state change is an EOA nonce increment, remove it.
    ///       2. Remove the following state changes from Gnosis Safes:
    ///           1. Nonce increments.
    ///           2. Setting an approve hash in storage (the hash is dependent on the nonce, which may change)
    ///       3. If the storage slot contains a timestamp, normalize that timestamp to be all zeroes.
    ///           1. This will have to be informed by knowing the storage layouts, which is ok
    ///           2. We should only normalize the specific section of the slot corresponding to the
    ///              timestamp, since some timestamps are packed into slots with other data.
    ///       4. If the slot is on the LivenessGuard, remove it.
    ///   5. The hash to return is computed as `keccak256(abi.encode(normalizedArray))`.
    /// @return bytes32 hash of the normalized state diff
    function normalizedStateDiffHash(
        VmSafe.AccountAccess[] memory _accountAccesses,
        address _parentMultisig,
        bytes32 _txHash
    ) internal view noGasMetering returns (bytes32) {
        // Get all storage writes as a state diff.
        address[] memory uniqueAddresses = getUniqueWrites({accesses: _accountAccesses, _sort: false});

        // Create a temporary array to store normalized state changes.
        AccountStateDiff[] memory normalizedChanges = new AccountStateDiff[](MAX_STATE_CHANGES);
        uint256 normalizedCount = 0;

        // Process each account with storage writes.
        for (uint256 i = 0; i < uniqueAddresses.length; i++) {
            address account = uniqueAddresses[i];
            StateDiff[] memory diffs = getStateDiffFor({accesses: _accountAccesses, who: account, _sort: false});

            // Process each diff and apply normalization logic.
            for (uint256 j = 0; j < diffs.length; j++) {
                StateDiff memory diff = diffs[j];
                if (shouldIncludeDiff(account, diff, _parentMultisig, _txHash)) {
                    diff = normalizeTimestamp(account, diff); // Normalize the timestamp if present.
                    normalizedChanges[normalizedCount] = AccountStateDiff({
                        who: account,
                        slot: diff.slot,
                        firstOld: diff.oldValue,
                        lastNew: diff.newValue
                    });
                    normalizedCount++;
                    require(normalizedCount < MAX_STATE_CHANGES, "AccountAccessParser: Max state changes reached");
                }
            }
        }

        // Create the final array with the correct size.
        AccountStateDiff[] memory finalArray = new AccountStateDiff[](normalizedCount);
        for (uint256 i = 0; i < normalizedCount; i++) {
            finalArray[i] = normalizedChanges[i];
        }

        // Return keccak256 hash of the abi-encoded normalized array.
        return keccak256(abi.encode(finalArray));
    }

    function shouldIncludeDiff(address account, StateDiff memory diff, address _parentMultisig, bytes32 _txHash)
        internal
        view
        returns (bool)
    {
        if (isEOANonceIncrement(account, diff)) {
            // 1. If the state change is an EOA nonce increment, remove it.
            return false;
        } else if (isGnosisSafe(account)) {
            // 2. Remove Gnosis Safe nonce increment and approve hash changes.
            if (isGnosisSafeNonceIncrement(diff) || isGnosisSafeApproveHash(diff, _parentMultisig, _txHash)) {
                // 2.1 Nonce increment or 2.2 Setting an approve hash in storage.
                return false;
            }
        } else if (isLivenessGuardTimestamp(account, diff, _parentMultisig)) {
            // 4. If the slot is on the LivenessGuard, don't include it.
            return false;
        } else if (isOptimismPortalResourceMetering(diff)) {
            // 5. If the slot is on the OptimismPortalResourceParams, don't include it.
            return false;
        } else if (isAnchorStateRegistryProposal(account, diff)) {
            // 6. If the diff is an AnchorStateRegistry Proposal, don't include it.
            return false;
        }
        return true;
    }

    /// @notice Any function in the OptimismPortal that has the 'metered' modifier will have a non-deterministic state change.
    function isOptimismPortalResourceMetering(StateDiff memory _diff) internal view returns (bool) {
        if (_diff.slot == OPTIMISM_PORTAL_RESOURCE_PARAMS_SLOT) {
            // Extract prevBlockNum from the packed value. It's located in the most significant 64 bits.
            // ResourceParams is packed as follows: prevBlockNum (64 bits) | prevBoughtGas (64 bits) | prevBaseFee (128 bits)
            uint256 prevBlockNum = uint64(uint256(_diff.newValue) >> (128 + 64));
            // If the current block number is equal to the new values prevBlockNum, then we should remove this
            // state change because it means we have a nondeterministic change based on block number at simulation time
            return block.number == prevBlockNum;
        }
        return false;
    }

    /// @notice Checks if the state diff represents an EOA nonce increment
    function isEOANonceIncrement(address _account, StateDiff memory _diff) internal view returns (bool) {
        uint256 codeSize = _account.code.length;
        return codeSize == 0 && _diff.slot == bytes32(0) && uint256(_diff.newValue) == uint256(_diff.oldValue) + 1;
    }

    /// @notice Checks if the state diff represents a Gnosis Safe nonce increment
    function isGnosisSafeNonceIncrement(StateDiff memory _diff) internal pure returns (bool) {
        // In Gnosis Safe, the nonce is stored at slot 5. See `GnosisSafeStorage.sol` to verify.
        return _diff.slot == GNOSIS_SAFE_NONCE_SLOT && uint256(_diff.newValue) == uint256(_diff.oldValue) + 1;
    }

    /// @notice Checks if the state diff represents setting an approve hash in a Gnosis Safe
    function isGnosisSafeApproveHash(StateDiff memory _diff, address _parentMultisig, bytes32 _txHash)
        internal
        view
        returns (bool)
    {
        bytes32[] memory hashSlots = calculateApproveHashSlots(IGnosisSafe(_parentMultisig).getOwners(), _txHash);
        for (uint256 i = 0; i < hashSlots.length; i++) {
            if (_diff.slot == hashSlots[i]) {
                require(
                    (_diff.oldValue == bytes32(0) && _diff.newValue == bytes32(uint256(1)))
                    // Some Gnosis Safe versions set approvedHashes to zero upon execution e.g. mainnet FoundationOperationsSafe.
                    || (_diff.oldValue == bytes32(uint256(1)) && _diff.newValue == bytes32(0)),
                    "AccountAccessParser: Unexpected approve hash state change."
                );
                return true;
            }
        }
        return false;
    }

    /// @notice Checks if the given slot matches any liveness guard timestamp for the signers on child multisigs.
    function isLivenessGuardTimestamp(address _account, StateDiff memory _diff, address _parentMultisig)
        internal
        view
        returns (bool)
    {
        if (isLivenessGuard(_account)) {
            address[] memory owners = IGnosisSafe(_parentMultisig).getOwners();
            for (uint256 i = 0; i < owners.length; i++) {
                if (isGnosisSafe(owners[i])) {
                    // Get the owners of the nested Gnosis Safe.
                    address[] memory nestedSafeOwners = IGnosisSafe(owners[i]).getOwners();
                    for (uint256 j = 0; j < nestedSafeOwners.length; j++) {
                        // Check if the slot matches any liveness guard timestamp for the nested safe owners.
                        bytes32 ownerSlot =
                            keccak256(abi.encode(address(nestedSafeOwners[j]), LIVENESS_GUARD_LAST_LIVE_SLOT));
                        if (_diff.slot == ownerSlot) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    function isAnchorStateRegistryProposal(address _account, StateDiff memory _diff) internal view returns (bool) {
        if (isAnchorStateRegistry(_account)) {
            // The proposal is stored in slot 3 and 4.
            return _diff.slot == ANCHOR_STATE_REGISTRY_PROPOSAL_ROOT_SLOT
                || _diff.slot == ANCHOR_STATE_REGISTRY_PROPOSAL_L2_SEQUENCE_NUMBER_SLOT;
        }
        return false;
    }

    /// @notice Normalizes a timestamp in a storage slot by zeroing out only the timestamp portion if present.
    function normalizeTimestamp(address _account, StateDiff memory _diff) internal view returns (StateDiff memory) {
        if (_diff.slot == ANCHOR_STATE_REGISTRY_RETIREMENT_TIMESTAMP_SLOT) {
            if (isAnchorStateRegistry(_account)) {
                // The retirementTimestamp is introduced in the AnchorStateRegistry post op-contracts/v3.0.0-rc.2.
                // Define a static mask to zero out 64 bits at offset 4 in little-endian format
                bytes32 MASK = bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFFFFFF);
                // Apply the static mask to zero out the specified bytes in the new value
                _diff.newValue &= MASK;
            }
        }
        return _diff;
    }

    /// @notice Extracts all unique storage writes (i.e. writes where the value has actually changed)
    function getUniqueWrites(VmSafe.AccountAccess[] memory accesses, bool _sort)
        internal
        pure
        returns (address[] memory uniqueAccounts)
    {
        // Temporary array sized to maximum possible length.
        address[] memory temp = new address[](MAX_STATE_CHANGES);
        uint256 count = 0;
        for (uint256 i = 0; i < accesses.length; i++) {
            bool hasChangedWrite = false;
            VmSafe.StorageAccess memory sa;
            for (uint256 j = 0; j < accesses[i].storageAccesses.length; j++) {
                sa = accesses[i].storageAccesses[j];
                if (sa.isWrite && !sa.reverted && sa.previousValue != sa.newValue) {
                    hasChangedWrite = true;
                    break;
                }
            }
            if (hasChangedWrite) {
                bool exists = false;
                for (uint256 k = 0; k < count; k++) {
                    if (temp[k] == sa.account) {
                        exists = true;
                        break;
                    }
                }
                if (!exists) {
                    temp[count] = sa.account;
                    count++;
                }
            }
        }
        uniqueAccounts = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            uniqueAccounts[i] = temp[i];
        }

        // sort the unique accounts
        if (_sort) {
            LibSort.sort(uniqueAccounts);
        }
    }

    /// @notice Extracts the net state diffs for a given account from the provided account accesses.
    /// It deduplicates writes by slot and returns an array of StateDiff structs where each slot
    /// appears only once and for each entry oldValue != newValue.
    function getStateDiffFor(VmSafe.AccountAccess[] memory accesses, address who, bool _sort)
        internal
        pure
        returns (StateDiff[] memory diffs)
    {
        // Over-allocate to the maximum possible number of diffs.
        StateDiff[] memory temp = new StateDiff[](MAX_STATE_CHANGES);
        uint256 diffCount = 0;

        for (uint256 i = 0; i < accesses.length; i++) {
            if (!accesses[i].reverted) {
                for (uint256 j = 0; j < accesses[i].storageAccesses.length; j++) {
                    VmSafe.StorageAccess memory sa = accesses[i].storageAccesses[j];
                    if (sa.account == who && sa.isWrite && !sa.reverted && sa.previousValue != sa.newValue) {
                        // Check if we already recorded a diff for this slot.
                        bool found = false;
                        for (uint256 k = 0; k < diffCount; k++) {
                            if (temp[k].slot == sa.slot) {
                                // Update the new value.
                                temp[k].newValue = sa.newValue;
                                found = true;
                                break;
                            }
                        }
                        if (!found) {
                            temp[diffCount] =
                                StateDiff({slot: sa.slot, oldValue: sa.previousValue, newValue: sa.newValue});
                            diffCount++;
                        }
                    }
                }
            }
        }
        // Filter out diffs where the net change is zero.
        uint256 finalCount = 0;
        for (uint256 i = 0; i < diffCount; i++) {
            if (temp[i].oldValue != temp[i].newValue) {
                temp[finalCount] = temp[i];
                finalCount++;
            }
        }

        // Allocate and copy the final array.
        diffs = new StateDiff[](finalCount);
        for (uint256 i = 0; i < finalCount; i++) {
            diffs[i] = temp[i];
        }

        if (_sort && finalCount > 1) {
            sortStateDiffsBySlot(diffs);
        }
    }

    // =========================================
    // ======== Internal helper methods ========
    // =========================================

    /// @notice Sorts an array of StateDiff structs by their slot values in ascending order
    function sortStateDiffsBySlot(StateDiff[] memory diffs) internal pure {
        uint256 length = diffs.length;
        // Simple bubble sort implementation
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                if (uint256(diffs[j].slot) > uint256(diffs[j + 1].slot)) {
                    StateDiff memory temp = diffs[j];
                    diffs[j] = diffs[j + 1];
                    diffs[j + 1] = temp;
                }
            }
        }
    }

    /// @notice Prints the decoded transfers and state diffs to the console.
    function print(
        DecodedTransfer[] memory _transfers,
        DecodedStateDiff[] memory _stateDiffs,
        address _parentMultisig,
        bytes32 _txHash
    ) internal view noGasMetering {
        console.log("");
        string memory line = unicode"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        console.log(string("TASK TRANSFERS").cyan().bold());
        console.log(line.cyan().bold());
        if (_transfers.length == 0) {
            console.log("No ETH or ERC20 transfers.");
        } else {
            printCopyHelper("below");
            for (uint256 i = 0; i < _transfers.length; i++) {
                DecodedTransfer memory transfer = _transfers[i];
                console.log("\n#### Decoded Transfer %s", i);
                console.log("- **From:**              `%s`", transfer.from);
                console.log("- **To:**                `%s`", transfer.to);
                console.log("- **Value:**             `%s`", transfer.value);
                console.log("- **Token Address:**     `%s`", transfer.tokenAddress);
            }
            printCopyHelper("above");
        }

        console.log("");
        console.log(string("TASK STATE CHANGES").cyan().bold());
        console.log(line.cyan().bold());
        printCopyHelper("below");
        require(_stateDiffs.length > 0, "No state changes found, this is unexpected.");
        printMarkdown(_stateDiffs, _parentMultisig, _txHash);
        printCopyHelper("above");
    }

    function printCopyHelper(string memory _text) internal view noGasMetering {
        string memory line = unicode"━━━━━";
        // forgefmt: disable-start
        string memory helper = string.concat(line, " Attention: Copy content ", _text, " this line into the VALIDATION.md file. ", line);
        // forgefmt: disable-end
        console.log(helper.yellow().bold());
    }

    /// @notice Prints the decoded state diffs to the console in markdown format.
    /// This markdown is intended to be copied into the VALIDATION.md file.
    function printMarkdown(DecodedStateDiff[] memory _stateDiffs, address _parentMultisig, bytes32 _txHash)
        internal
        view
        noGasMetering
    {
        address currentAddress = address(0xdead);
        for (uint256 i = 0; i < _stateDiffs.length; i++) {
            if (currentAddress != _stateDiffs[i].who) {
                console.log("");
                console.log("---"); // Add markdown horizontal rule.
                string memory currentChainId = _stateDiffs[i].l2ChainId == 0
                    ? ""
                    : string.concat("- Chain ID: ", vm.toString(_stateDiffs[i].l2ChainId));
                string memory currentContractName = bytes(_stateDiffs[i].contractName).length > 0
                    ? string.concat(_stateDiffs[i].contractName)
                    : "<TODO: enter contract name>";
                string memory addressString =
                    string.concat("\n### ", "`", LibString.toHexString(_stateDiffs[i].who), "`");
                console.log(addressString, string.concat("(", currentContractName, ") ", currentChainId));
                currentAddress = _stateDiffs[i].who;
            }
            DecodedStateDiff memory state = _stateDiffs[i];
            console.log("\n- **Key:**          `%s`", vm.toString(state.raw.slot));
            if (bytes(state.decoded.kind).length == 0) {
                string memory optionalSummary = bytes(state.decoded.summary).length > 0 ? state.decoded.summary : "";
                string memory optionalDetail = bytes(state.decoded.detail).length > 0 ? state.decoded.detail : "";
                console.log("- **Before:** `%s`", vm.toString(state.raw.oldValue));
                console.log("- **After:** `%s`", vm.toString(state.raw.newValue));
                console.log("- **Summary:** %s", optionalSummary);
                console.log("- **Detail:** %s", optionalDetail);
                if (bytes(optionalDetail).length == 0) {
                    console.log(
                        "\n**<TODO: Slot was not automatically decoded. Please provide a summary with thorough detail then remove this line.>**"
                    );
                }
            } else {
                console.log("- **Decoded Kind:** `%s`", state.decoded.kind);
                console.log("- **Before:** `%s`", state.decoded.oldValue);
                console.log("- **After:** `%s`", state.decoded.newValue);
                console.log("- **Summary:** %s", state.decoded.summary);
                console.log("- **Detail:** %s", state.decoded.detail);
            }
            console.log("\n**<TODO: Insert links for this state change then remove this line.>**");
            if (state.who == _parentMultisig) {
                // May need to log additional information here about approveHash writes.
                printApproveHashInfo(_parentMultisig, _txHash, state.raw.slot);
            }
        }
    }

    /// @notice Given an account access record, returns true if it contains a value transfer. Either an ETH transfer or an ERC20 transfer.
    function containsValueTransfer(VmSafe.AccountAccess memory access) internal pure returns (bool) {
        return getETHTransfer(access).value != 0 || getERC20Transfer(access).value != 0;
    }

    /// @notice Decodes an ETH transfer from an account access and returns an empty struct
    /// if no transfer occurred. This function does not yet support Create or SelfDestruct ETH transfers. It also
    /// assumes that accesses with DelegateCall kind are not ETH transfers.
    function getETHTransfer(VmSafe.AccountAccess memory access) internal pure returns (DecodedTransfer memory) {
        bool isEthTransfer = access.value != 0 && !access.reverted && access.oldBalance != access.newBalance;
        if (isEthTransfer) {
            require(
                access.kind != VmSafe.AccountAccessKind.SelfDestruct,
                "ETH transfer with SelfDestruct is not yet supported"
            );
            require(access.kind != VmSafe.AccountAccessKind.Create, "ETH transfer with Create is not yet supported");
            if (access.kind == VmSafe.AccountAccessKind.Call) {
                return DecodedTransfer({
                    from: access.accessor,
                    to: access.account,
                    value: access.value,
                    tokenAddress: ETHER
                });
            } else {
                require(access.kind == VmSafe.AccountAccessKind.DelegateCall, "Expected kind to be DelegateCall.");
                console.log(
                    string.concat(
                        string("[INFO]").green().bold(),
                        " ETH transfers via DelegateCall are not possible so this foundry account access will be ignored."
                    )
                );
            }
        }
        return DecodedTransfer({from: ZERO, to: ZERO, value: 0, tokenAddress: ZERO});
    }

    /// @notice Decodes an ERC20 transfer from an account access record, and returns an empty struct
    /// if no ERC20 transfer is detected.
    function getERC20Transfer(VmSafe.AccountAccess memory access) internal pure returns (DecodedTransfer memory) {
        bytes memory data = access.data;
        if (data.length <= 4) return DecodedTransfer({from: ZERO, to: ZERO, value: 0, tokenAddress: ZERO});

        bytes4 selector = bytes4(data);
        bytes memory params = new bytes(data.length - 4);
        for (uint256 j = 0; j < data.length - 4; j++) {
            params[j] = data[j + 4];
        }

        bool reverted = access.reverted;
        if (selector == IERC20.transfer.selector && !reverted) {
            (address to, uint256 value) = abi.decode(params, (address, uint256));
            return DecodedTransfer({from: access.accessor, to: to, value: value, tokenAddress: access.account});
        } else if (selector == IERC20.transferFrom.selector && !reverted) {
            (address from, address to, uint256 value) = abi.decode(params, (address, address, uint256));
            return DecodedTransfer({from: from, to: to, value: value, tokenAddress: access.account});
        } else {
            return DecodedTransfer({from: ZERO, to: ZERO, value: 0, tokenAddress: ZERO});
        }
    }

    /// @notice Given an address, returns the contract name and L2 chain ID for the contract.
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

        if (_slot == PROXY_OWNER_ADDR_SLOT) {
            return DecodedSlot({
                kind: "address",
                oldValue: toAddress(_oldValue),
                newValue: toAddress(_newValue),
                summary: "Proxy owner address",
                detail: "Standard slot for storing the owner address in a Proxy contract."
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
                oldValue: toUint256(_oldValue),
                newValue: toUint256(_newValue),
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
                oldValue: toUint256(_oldValue),
                newValue: toUint256(_newValue),
                summary: "Required protocol version",
                detail: "Unstructured storage slot for the required protocol version."
            });
        }
        if (_slot == RECOMMENDED_SLOT) {
            return DecodedSlot({
                kind: "uint256",
                oldValue: toUint256(_oldValue),
                newValue: toUint256(_newValue),
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
            console.log(string.concat(string("[WARN]").yellow().bold(), "Failed to read storage layout file at ", path));
            return DecodedSlot({kind: "", oldValue: "", newValue: "", summary: "", detail: ""});
        }
        bytes memory parsedStorageLayout = vm.parseJson(storageLayout, "$");
        JsonStorageLayout[] memory layout = abi.decode(parsedStorageLayout, (JsonStorageLayout[]));

        // Iterate over the storage layout and look for the slot.
        for (uint256 i = 0; i < layout.length; i++) {
            // Decode the slot if it is shared and add the info to the summary and detail sections.
            if (isSlotShared(layout, _slot)) {
                return decodeSharedSlot(layout, _slot, _oldValue, _newValue);
            }

            if (vm.parseUint(layout[i]._slot) == uint256(_slot)) {
                return decodeSlot(layout[i], _oldValue, _newValue);
            }
        }
    }

    /// @notice Decodes a shared storage slot.
    function decodeSharedSlot(JsonStorageLayout[] memory layout, bytes32 slot, bytes32 _oldValue, bytes32 _newValue)
        internal
        pure
        returns (DecodedSlot memory decoded_)
    {
        JsonStorageLayout[] memory layouts = getSharedSlotLayouts(layout, slot);
        string memory summary = "Multiple variables share this storage slot. Details below.";
        string memory detail;
        for (uint256 j = 0; j < layouts.length; j++) {
            DecodedSlot memory decoded = decodeSlot(layouts[j], _oldValue, _newValue);
            if (!decoded.oldValue.eq(decoded.newValue)) {
                string memory kind = string.concat("(`", decoded.kind, "`)");
                // forgefmt: disable-next-line
                detail = string.concat(detail, "", kind, " ", layouts[j]._label, " `", decoded.oldValue, "` &rarr; `", decoded.newValue, "`, ");
            }
        }
        return DecodedSlot({kind: "", oldValue: "", newValue: "", summary: summary, detail: detail});
    }

    /// @notice Decodes a non-shared storage slot.
    function decodeSlot(JsonStorageLayout memory item, bytes32 _oldValue, bytes32 _newValue)
        internal
        pure
        returns (DecodedSlot memory decoded_)
    {
        // Decode the 32-byte value based on the size and offset of the slot.
        string memory kind = item._type;
        uint256 offset = item._offset;
        string memory oldValue;
        string memory newValue;
        if (kind.eq("bool")) {
            oldValue = toBool(_oldValue, offset);
            newValue = toBool(_newValue, offset);
        } else if (kind.eq("address")) {
            oldValue = toAddress(_oldValue, offset);
            newValue = toAddress(_newValue, offset);
            // We're not exhaustively handling all uint types here.
            // We will add more as needed.
        } else if (kind.contains("uint32")) {
            oldValue = toUint32(_oldValue, offset);
            newValue = toUint32(_newValue, offset);
        } else if (kind.contains("uint64")) {
            oldValue = toUint64(_oldValue, offset);
            newValue = toUint64(_newValue, offset);
        } else if (kind.contains("uint256")) {
            oldValue = toUint256(_oldValue, offset);
            newValue = toUint256(_newValue, offset);
        }

        string memory label = item._label;
        return DecodedSlot({kind: kind, oldValue: oldValue, newValue: newValue, summary: label, detail: ""});
    }

    /// @notice Returns true if a storage slot appears more than once in the layout, indicating tight packing.
    /// A tightly packed (shared) slot is one reused by multiple storage variables.
    function isSlotShared(JsonStorageLayout[] memory layout, bytes32 slot) internal pure returns (bool) {
        uint256 occurrences = 0;
        for (uint256 i = 0; i < layout.length; i++) {
            if (vm.parseUint(layout[i]._slot) == uint256(slot)) {
                occurrences++;
                if (occurrences > 1) return true;
            }
        }
        return false;
    }

    function getSharedSlotLayouts(JsonStorageLayout[] memory layout, bytes32 slot)
        internal
        pure
        returns (JsonStorageLayout[] memory layouts_)
    {
        // Count matching items
        uint256 occurrences = 0;
        for (uint256 i = 0; i < layout.length; i++) {
            if (vm.parseUint(layout[i]._slot) == uint256(slot)) {
                occurrences++;
            }
        }

        // Create appropriately sized array
        layouts_ = new JsonStorageLayout[](occurrences);

        uint256 resultIndex = 0;
        for (uint256 i = 0; i < layout.length; i++) {
            if (vm.parseUint(layout[i]._slot) == uint256(slot)) {
                layouts_[resultIndex] = layout[i];
                resultIndex++;
            }
        }

        return layouts_;
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

        // Log a warning if the address is not found in the superchain-registry. The superchain-registry usually lags
        // behind the latest release and it's expected that some addresses are not yet registered.
        if (!Utils.isFeatureEnabled("SIGNING_MODE_IN_PROGRESS")) {
            console.log(
                string.concat(
                    string("[WARN]").yellow().bold(),
                    " Target address not found in superchain-registry (this message is safe to ignore): ",
                    vm.toString(target)
                )
            );
        }
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

    /// @notice Probabilistically check if an address is an AnchorStateRegistry.
    function isAnchorStateRegistry(address _who) internal view returns (bool) {
        bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("getAnchorRoot()")));
        (bool ok, bytes memory data) = _who.staticcall(callData);
        return ok && data.length == 64;
    }

    /// @notice Pre-calculate all hash approval slots for a given multisig and hash.
    function calculateApproveHashSlots(address[] memory _owners, bytes32 _hash)
        internal
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory hashSlots = new bytes32[](_owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            bytes32 ownerSlot = keccak256(abi.encode(_owners[i], GNOSIS_SAFE_APPROVE_HASHES_SLOT));
            hashSlots[i] = keccak256(abi.encode(_hash, ownerSlot));
        }
        return hashSlots;
    }

    /// @notice Prints information about the `approveHash` state changes.
    /// During local simulation, we call `approveHash` for each multisig owner.
    /// In some GnosisSafe versions, the `approveHash` mapping resets to zero during execution.
    /// These state changes are normal in simulation but uncommon in production, where signers typically provide signatures directly.
    /// This function prints more information for the task developer to understand the state changes when writing each task's VALIDATION.md file.
    function printApproveHashInfo(address _parentMultisig, bytes32 _hash, bytes32 _slot) internal view {
        address[] memory owners = IGnosisSafe(_parentMultisig).getOwners();
        bytes32[] memory hashSlots = calculateApproveHashSlots(owners, _hash);
        for (uint256 k = 0; k < hashSlots.length; k++) {
            if (_slot == hashSlots[k]) {
                console.log(
                    "\n**<TODO: This slot is an approveHash write for the owner %s on the multisig: %s>**",
                    vm.toString(owners[k]),
                    vm.toString(_parentMultisig)
                );
                console.log(
                    "\n**<TODO: Consider removing this write from state changes in the VALIDATION.md file (Note: please ask internally if you are unsure).>**\n"
                );
                break;
            }
        }
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

    function toUint256(bytes32 _value) internal pure returns (string memory) {
        return toUint256(_value, 0);
    }

    function toUint256(bytes32 _value, uint256 _offset) internal pure returns (string memory) {
        return vm.toString(uint256(_value) >> (_offset * 8));
    }

    function toUint32(bytes32 _value, uint256 _offset) internal pure returns (string memory) {
        return vm.toString(uint32(uint256(_value) >> (_offset * 8)));
    }

    function toUint64(bytes32 _value, uint256 _offset) internal pure returns (string memory) {
        return vm.toString(uint64(uint256(_value) >> (_offset * 8)));
    }
}
