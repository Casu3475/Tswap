/**
 * /-\|/-\|/-\|/-\|/-\|/-\|/-\|/-\|/-\|/-\
 * |                                     |
 * \ _____    ____                       /
 * -|_   _|  / ___|_      ____ _ _ __    -
 * /  | |____\___ \ \ /\ / / _` | '_ \   \
 * |  | |_____|__) \ V  V / (_| | |_) |  |
 * \  |_|    |____/ \_/\_/ \__,_| .__/   /
 * -                            |_|      -
 * /                                     \
 * |                                     |
 * \-/|\-/|\-/|\-/|\-/|\-/|\-/|\-/|\-/|\-/
 */
// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity 0.8.20;

import { TSwapPool } from "./TSwapPool.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

contract PoolFactory {
    error PoolFactory__PoolAlreadyExists(address tokenAddress);

    // this error is not used !
    error PoolFactory__PoolDoesNotExist(address tokenAddress);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    mapping(address token => address pool) private s_pools; // probably poolToken -> pool
    mapping(address pool => address token) private s_tokens; // mapping back

    address private immutable i_wethToken; // the weth token is immutable because every token pair with weth

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event PoolCreated(address tokenAddress, address poolAddress);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address wethToken) {
        i_wethToken = wethToken;
    } // missing 0 address check

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // e tokenAddress -> weth for a token/weth pool
    function createPool(address tokenAddress) external returns (address) { 
        if (s_pools[tokenAddress] != address(0)) {   // it's checking if the pool already exists
            revert PoolFactory__PoolAlreadyExists(tokenAddress); // we can not create a pool that already exists
        }
        // e "T-swap DAI"
        // q weird ERC20 "what if the name function reverts ?"
        string memory liquidityTokenName = string.concat("T-Swap ", IERC20(tokenAddress).name());
        // "tsUSDC"
        // @audit-info this should be .symbol() not .name() -> look at the ERC20.sol
        string memory liquidityTokenSymbol = string.concat("ts", IERC20(tokenAddress).name());

        TSwapPool tPool = new TSwapPool(
            tokenAddress, // check the constructor in TSwapPool.sol
            i_wethToken, // check the constructor in TSwapPool.sol
            liquidityTokenName, 
            liquidityTokenSymbol
            );
        s_pools[tokenAddress] = address(tPool); 
        s_tokens[address(tPool)] = tokenAddress;
        emit PoolCreated(tokenAddress, address(tPool));
        return address(tPool);
    }

    /*//////////////////////////////////////////////////////////////
                   EXTERNAL AND PUBLIC VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getPool(address tokenAddress) external view returns (address) {
        return s_pools[tokenAddress];
    }

    function getToken(address pool) external view returns (address) {
        return s_tokens[pool];
    }

    function getWethToken() external view returns (address) {
        return i_wethToken;
    }
}
