// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAaveLendingPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IPlatypusPool {
    function deposit(
        address token,
        uint256 amount, 
        address to,
        uint256 deadline
    ) external returns (uint256);
    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256);
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256, uint256);  
    function assetOf(address token) external view returns (address);
}

interface IMasterPlatypusV4 {
    function deposit(
        uint256 _pid, 
        uint256 amount
    ) external returns (uint256, uint256[] memory);
    function getPoolId(address _lp) external view returns (uint256);
    function emergencyWithdraw(uint256 _pid) external;
}

interface IPlatypusTreasure {
    struct PositionView {
        uint256 collateralAmount;
        uint256 collateralUSD;
        uint256 borrowLimitUSP;
        uint256 liquidateLimitUSP;
        uint256 debtAmountUSP;
        uint256 debtShare;
        uint256 healthFactor;
        bool liquidable;
    }
    function positionView(
        address _user, 
        address _token
    ) external view returns (PositionView memory);
    function borrow(address _token, uint256 _borrowAmount) external;
}