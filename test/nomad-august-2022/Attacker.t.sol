// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/nomad-august-2022/Attacker.sol";

contract NomadAttackerTest is Test {
    function setUp() public {
        vm.createSelectFork("mainnet", 15259100);
    }

    function testAttack() public {
       Attacker attacker = new Attacker();

       attacker.attack();
    }
}
