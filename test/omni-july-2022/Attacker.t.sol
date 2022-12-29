// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/omni-july-2022/Attacker.sol";

contract AttackerTest is Test {
    function setUp() public {
        vm.createSelectFork("mainnet", 15114361);
    }

    function testAttack() public {
        Liquidator attacker = new Liquidator();
        attacker.startExploit();   
    }
}
