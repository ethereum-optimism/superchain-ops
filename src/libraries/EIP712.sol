// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";

contract EIP712 is Script {
    function run() public pure {
        bytes memory data =
            hex"1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111";
        GnosisSafeHashes.SafeTransaction memory safeTx = GnosisSafeHashes.SafeTransaction({
            to: 0x1111111111111111111111111111111111111111,
            value: 0,
            data: data,
            operation: 0,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: 0x0000000000000000000000000000000000000000,
            refundReceiver: 0x0000000000000000000000000000000000000000,
            nonce: 1
        });
        GnosisSafeHashes.generateTypedDataJson(100, 0x2222222222222222222222222222222222222222, safeTx);
    }
}
