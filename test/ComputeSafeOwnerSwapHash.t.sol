// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {ComputeSafeOwnerSwapHash} from "src/script/ComputeSafeOwnerSwapHash.s.sol";

// Forge v1 will not support `expectRevert` on internal calls, so use a harness to expose the
// internal functions and test them using external calls. Learn more:
//   https://book.getfoundry.sh/guides/v1.0-migration#expect-revert-cheatcode-disabled-on-internal-calls-by-default
contract ComputeSafeOwnerSwapHashHarness is ComputeSafeOwnerSwapHash {
    function exposed_getTxDataAndHash(address _safe, address _oldOwner, address _newOwner)
        public
        view
        returns (bytes memory txData_, bytes32 dataHash_)
    {
        return getTxDataAndHash(_safe, _oldOwner, _newOwner);
    }

    function exposed_findPreviousOwner(address[] memory _owners, address _owner)
        public
        pure
        returns (address prevOwner_, uint256 prevOwnerIndex_)
    {
        return findPreviousOwner(_owners, _owner);
    }
}

contract ComputeSafeOwnerSwapHashTest is Test {
    address internal constant SENTINEL_OWNERS = address(0x1);
    ComputeSafeOwnerSwapHashHarness internal harness;

    function setUp() public {
        harness = new ComputeSafeOwnerSwapHashHarness();
        vm.makePersistent(address(harness));
    }

    function test_getTxDataAndHash_succeeds() public {
        // We test using two prior swapOwner calls on the Yearn treasury. We extract the truth values
        // from the executed transaction, and fork from the block before the transaction was executed.
        address safe = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52; // Yearn treasury.

        // First transaction: https://etherscan.io/tx/0x9ec1f4f0895346c74dd87b41858f41e6c1ab3b86c6a0fc8c778bae00385cacc2
        uint256 blockNumber = 21008343;
        address oldOwner = 0x74630370197b4c4795bFEeF6645ee14F8cf8997D;
        address newOwner = 0x962228a90eaC69238c7D1F216d80037e61eA9255;

        vm.createSelectFork("mainnet", blockNumber);
        (bytes memory txData, bytes32 dataHash) = harness.exposed_getTxDataAndHash(safe, oldOwner, newOwner);
        bytes32 expectedDataHash = 0xd72a1a085cf390e66bcf5f5bda73939067e7da842c4b687b0169c1f25768a5a8;
        bytes memory expectedTxData =
            hex"190188fbc465dedd7fe71b7baef26a1f46cdaadd50b95c77cbe88569195a9fe589abe8a1602017dea9860ec8deacad810c9b605285c389cb885f7a8647a230e8fe57";

        assertEq(dataHash, expectedDataHash, "100");
        assertEq(txData, expectedTxData, "200");

        // Second transaction: https://etherscan.io/tx/0x94321304e046deb167d3ae4183887a1bc61349d985decb8c4d76414e8e275429
        blockNumber = 21014968;
        oldOwner = 0x0Cec743b8CE4Ef8802cAc0e5df18a180ed8402A7;
        newOwner = 0xFe45baf0F18c207152A807c1b05926583CFE2e4b;

        vm.createSelectFork("mainnet", blockNumber);
        (txData, dataHash) = harness.exposed_getTxDataAndHash(safe, oldOwner, newOwner);
        expectedDataHash = 0x349ead35f44eac541dfd40662a02770f12951c5778802fd8adf535c4e6b70142;
        expectedTxData =
            hex"190188fbc465dedd7fe71b7baef26a1f46cdaadd50b95c77cbe88569195a9fe589ab4675354b61d8123307299cfff69f25a75001e490b6c7086f1dc8307a2197a713";

        assertEq(dataHash, expectedDataHash, "300");
        assertEq(txData, expectedTxData, "400");
    }

    function test_findPreviousOwner_succeeds() public {
        address[] memory owners = new address[](4);
        owners[0] = SENTINEL_OWNERS;
        owners[1] = makeAddr("owner1");
        owners[2] = makeAddr("owner2");
        owners[3] = makeAddr("owner3");

        // For the first owner, the function should return the sentinel address.
        (address prev1, uint256 index1) = harness.exposed_findPreviousOwner(owners, owners[0]);
        assertEq(prev1, SENTINEL_OWNERS, "100");
        assertEq(index1, 0, "200");

        // For the second owner, the function should return the first owner.
        (address prev2, uint256 index2) = harness.exposed_findPreviousOwner(owners, owners[1]);
        assertEq(prev2, owners[0], "300");
        assertEq(index2, 0, "400");

        // For the last owner, the function should return the third owner.
        (address prev3, uint256 index3) = harness.exposed_findPreviousOwner(owners, owners[3]);
        assertEq(prev3, owners[2], "500");
        assertEq(index3, 2, "600");
    }

    function test_findPreviousOwner_whenOwnerIsNotFound_reverts() public {
        address[] memory owners = new address[](4);
        owners[0] = SENTINEL_OWNERS;
        owners[1] = makeAddr("owner1");
        owners[2] = makeAddr("owner2");
        owners[3] = makeAddr("owner3");

        address nonOwner = makeAddr("nonOwner");
        vm.expectRevert(bytes(string.concat("Owner not found: ", vm.toString(nonOwner))));
        harness.exposed_findPreviousOwner(owners, nonOwner);
    }
}
