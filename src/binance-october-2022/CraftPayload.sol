pragma solidity ^0.8.13;

import "./RLPEncode.sol";
import "./RLPDecode.sol";
import "./Memory.sol";

contract CraftPayload {

    using RLPEncode for *;
    using RLPDecode for *;

    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

    function encodeSymbol()public pure returns(bytes memory){
        string memory _input = "BNB";
        bytes32 output;

        assembly {
            output := mload(add(_input, 0x20))
        }
        return uint256(output).encodeUint();
    }

    function craftPayload(address tokenAddress, uint256 amount, address recipient, uint256 expiryTime)external view returns(bytes memory _result2){
        bytes memory _result;
        _result = abi.encodePacked(encodeSymbol(), tokenAddress.encodeAddress(), amount.encodeUint(), recipient.encodeAddress(), recipient.encodeAddress(), uint256(expiryTime).encodeUint());
        _result = abi.encodePacked( _result.length.encodeUint(), _result);
        _result2 = abi.encodePacked( payloadHeader(), _result);
    }

    function payloadHeader()public pure returns(bytes memory payloadHeader) {
        uint8 SYN_PACKAGE = 0x00;
        uint256 RelayFee = 0;
        uint8 Separator = 0xf8;
        payloadHeader = abi.encodePacked(SYN_PACKAGE, RelayFee, Separator);
    }
 }