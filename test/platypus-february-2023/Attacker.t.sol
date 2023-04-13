// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/platypus-february-2023/Attacker.sol";

contract PlatypusAttackerTest is Test {

    function setUp() public {
        vm.createSelectFork("avax", 26343613);
    }

    function testAttack() public {
        Attacker attacker = new Attacker();
        
        attacker.attack();
        attacker.logBalances();
    }
}
