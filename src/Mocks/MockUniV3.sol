// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";
import {ISwapRouter} from "../interfaces/ISwapRouter.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

/// @title Mock UniV3
/// @dev This contract is used to replicate the main UniswapV3 contract logic
contract MockUniswapV3 {
    address[] s_tokens;
    uint256[] s_balances;
    uint256 s_tokenId;

    mapping(uint256 => uint128) public s_liquidity;

    mapping(address => mapping(address => uint256)) public prices;
    uint256 constant PRICE_SCALAR = 1e8;

    function registerAndMintToken(address token, uint256 mintAmount) external {
        ERC20(token).transferFrom(msg.sender, address(this), mintAmount);

        if (s_tokens.length == 0) {
            s_tokens = [token];
            s_balances = [mintAmount];
        } else {
            s_tokens.push(token);
            s_balances.push(mintAmount);
            return;
        }
    }

    function setPrice(address token0, address token1, uint256 price) external {
        prices[token0][token1] = price;
    }

    // * SWAP ROUTER LOGIC
    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut)
    {
        ERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);

        amountOut = params.amountIn * prices[params.tokenOut][params.tokenIn] / PRICE_SCALAR;

        ERC20(params.tokenOut).transfer(params.recipient, amountOut);
    }

    // * NON-FUNGIBLE POSITION MANAGER LOGIC
    function mint(INonfungiblePositionManager.MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        ERC20(params.token0).transferFrom(msg.sender, address(this), params.amount0Desired);
        ERC20(params.token1).transferFrom(msg.sender, address(this), params.amount1Desired);

        liquidity = uint128(params.amount0Desired + params.amount1Desired);

        s_tokenId++;

        s_liquidity[s_tokenId] = liquidity;

        return (s_tokenId, liquidity, params.amount0Desired, params.amount1Desired);
    }

    function decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1)
    {
        uint128 activeLiquidity = s_liquidity[params.tokenId];

        require(activeLiquidity >= params.liquidity, "Insufficient liquidity");

        amount0 = params.liquidity / 2;
        amount1 = params.liquidity / 2;

        ERC20(s_tokens[0]).transfer(msg.sender, amount0);
        ERC20(s_tokens[1]).transfer(msg.sender, amount1);

        s_liquidity[params.tokenId] -= params.liquidity;

        return (amount0, amount1);
    }

    function collect(INonfungiblePositionManager.CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1)
    {
        return (0, 0);
    }
}
