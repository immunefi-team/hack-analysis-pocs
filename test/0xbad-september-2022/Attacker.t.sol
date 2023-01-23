// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/0xbad-september-2022/Attacker.sol";

contract MEVBotAttackerTest is Test {
    function setUp() public {
        vm.createSelectFork("mainnet", 15625423);
        vm.label(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, "WETH");
        vm.label(0xbaDc0dEfAfCF6d4239BDF0b66da4D7Bd36fCF05A, "0xbad");
        vm.label(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e, "SoloMargin");
        vm.label(0xDd6Bd08c29fF3EF8780bF6A10D8b620A93AC5705, "0xDd6B");
        vm.label(0xdAC17F958D2ee523a2206206994597C13D831ec7, "USDT");
    }

    function testAttack() public {
       Attacker attacker = new Attacker();

       attacker.attack();
    }
}
