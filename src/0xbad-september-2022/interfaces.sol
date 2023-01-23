// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface SoloMargin {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (externally)
        Sell, // sell an amount of some token (externally)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }
    enum AssetDenomination { Wei, Par }

    enum AssetReference { Delta, Target }

    struct AccountInfo {
        address owner;
        uint256 number;
    }
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }
    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }
    struct Rate {
        uint256 value;
    }
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }
    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    function operate(
        Account.Info[] calldata accounts,
        ActionArgs[] calldata actions
    ) external;
}

library Account {
    struct Info {
        address owner;
        uint256 number;
    }
}