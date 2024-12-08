// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, StdInvariant, console2 } from "forge-std/Test.sol";
import { PoolFactory } from "../../src/PoolFactory.sol"; 
import { TSwapPool } from "../../src/TSwapPool.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { TSwapPoolHandler } from "./TSwapPoolHandler.sol";

contract Invariant is StdInvariant, Test {
    // these pools have 2 assets
    ERC20Mock poolToken;
    ERC20Mock weth; 
 
    ERC20Mock tokenB;

    // we are gonna need the contracts
    PoolFactory factory;
    TSwapPool pool; // poolToken / WETH

    int256 constant STARTING_X = 100e18; // starting ERC20 / poolToken
    int256 constant STARTING_Y = 50e18; // starting WETH
    uint256 constant FEE = 997e15; //
    int256 constant MATH_PRECISION = 1e18;

    TSwapPoolHandler handler;

    function setUp() public {
        // ----------------------
        // we have the pool ...
        // ----------------------
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken))); // liquidity providers !

        // Create the initial x & y values for the pool
        poolToken.mint(address(this), uint256(STARTING_X)); // Constant product formula
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        // deposit into the pool, give the starting X & Y balances
        // look at the TSwapPool.sol deposit function
        pool.deposit(
            uint256(STARTING_Y),  // wethToDeposit
            uint256(STARTING_Y),  // minimumLiquidityTokensToMint
            uint256(STARTING_X),  // maximumPoolTokensToDeposit
            uint64(block.timestamp)); // deadline

        // -------------
        // and then ...
        // -------------
        handler = new TSwapPoolHandler(pool);

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = TSwapPoolHandler.deposit.selector;
        selectors[1] = TSwapPoolHandler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    // Normal Invariant
    // x * y = k
    // x * y = (x + ∆x) * (y − ∆y)
    // x = Token Balance X
    // y = Token Balance Y
    // ∆x = Change of token balance X
    // ∆y = Change of token balance Y
    // β = (∆y / y)
    // α = (∆x / x)

    // Final invariant equation without fees:
    // ∆x = (β/(1-β)) * x
    // ∆y = (α/(1+α)) * y

    // Invariant with fees
    // ρ = fee (between 0 & 1, aka a percentage)
    // γ = (1 - p) (pronounced gamma)
    // ∆x = (β/(1-β)) * (1/γ) * x
    // ∆y = (αγ/1+αγ) * y
    function invariant_deltaXFollowsMath() public {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }

    // the change in the pool size of WETH should follow this function 
    // ∆x = (β/(1-β)) * x
    // in a handler, 
    // actual delta x == ∆x = (β/(1-β)) * x


    function invariant_deltaYFollowsMath() public {
        assertEq(handler.actualDeltaY(), handler.expectedDeltaY());
    }
}