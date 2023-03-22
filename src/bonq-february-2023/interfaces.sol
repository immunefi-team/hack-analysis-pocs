// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITellorFlex {
    function getStakeAmount() external returns (uint256);
    function depositStake(uint256 _amount) external;
    function submitValue(
        bytes32 _queryId,
        bytes calldata _value,
        uint256 _nonce,
        bytes calldata _queryData
    ) external;
}

interface ITrove {
    function increaseCollateral(uint256 _amount, address _newNextTrove) external;
    function borrow(address _recipient, uint256 _amount, address _newNextTrove) external;
    function debt() external view returns (uint256);
    function liquidate() external;
    function repay(uint256 _amount, address _newNextTrove) external;
    function decreaseCollateral(
        address _recipient,
        uint256 _amount,
        address _newNextTrove
    ) external;
}

interface IOriginalTroveFactory {
    function lastTrove(address _token) external view returns (address);
    function firstTrove(address _token) external view returns (address);
    function nextTrove(address _token, address _trove) external view returns (address);
    function troveCount(address _token) external view returns (uint256);
    function createTrove(address _token) external returns (ITrove trove);
}