// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {
    IUniswapV3Factory
} from "../../../src/interfaces/uniswap-v3/IUniswapV3Factory.sol";
import {
    IUniswapV3Pool
} from "../../../src/interfaces/uniswap-v3/IUniswapV3Pool.sol";
import {
    UNISWAP_V3_FACTORY,
    DAI,
    USDC,
    UNISWAP_V3_POOL_DAI_USDC_100
} from "../../../src/Constants.sol";
import {ERC20} from "../../../src/ERC20.sol";

contract UniswapV3SwapTest is Test {
    IWETH private weth = IWETH(WETH);
    IERC20 private dai = IERC20(DAI);
    IERC20 private wbtc = IERC20(WBTC);
    IswapRouter private Router = IswapRouter(UNISWAP_V3_SWAP_ROUTER_02);
    uint24 private constant POOL_FEE = 3000;

    function setUp() public {
        deal(DAI, address(this), 1000 * 1e18);
        dai.approve(address(Router), type(uint256).max);
    }

    // Exercise 1
    // - Swap 1000 DAI for WETH on DAI/WETH pool with 0.3% fee
    // - Send WETH from Uniswap V3 to this contract
    function test_swapExactInputSingle() public {
        // Write your code here
        uint256 amountOut = 0;
        amountOut = Router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH,
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp + 1 hours,
                amountIn: 1000 * 1e18,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        uint256 wethAfter = weth.balanceOf(address(this));

        console2.log("WETH amount out %e", amountOut);
        assertGt(amountOut, 0);
        assertEq(wethAfter - wethBefore, amountOut);
    }

    // Exercise 2
    // Swap 1000 DAI for WETH and then WETH to WBTC
    // - Swap DAI to WETH on pool with 0.3% fee
    // - Swap WETH to WBTC on pool with 0.3% fee
    // - Send WBTC from Uniswap V3 to this contract
    // NOTE: WBTC has 8 decimals
    function test_swapExactInput() public {
        // Write your code here
        // Call router.exactInput
        bytes memory path;
        uint256 amountOut = 0;
        path = abi.encodePacked(DAI, uint24(POOL_FEE), WETH, uint24(POOL_FEE), WBTC);
        amountOut = Router.exactInput(
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp + 1 hours,
                amountIn: 1000 * 1e18,
                amountOutMinimum: 0
            })
        );

        console2.log("WBTC amount out %e", amountOut);
        assertGt(amountOut, 0);
        assertEq(wbtc.balanceOf(address(this)), amountOut);
    }

    // Exercise 3
    // - Swap maximum of 1000 DAI to obtain exactly 0.1 WETH from DAI/WETH pool with 0.3% fee
    // - Send WETH from Uniswap V3 to this contract
    function test_swapExactOutputSingle() public {
        // Write your code here
        uint256 amountIn = 0;
        amountIn = Router.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH,
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp + 1 hours,
                amountOut: 0.1 * 1e18,
                amountInMaximum: 1000 * 1e18,
                sqrtPriceLimitX96: 0
            })
        );

        uint256 wethAfter = weth.balanceOf(address(this));

        console2.log("DAI amount in %e", amountIn);
        assertGt(amountIn, 0);
        assertEq(wethAfter - wethBefore, 0.1 * 1e18);
    }

    // Exercise 4
    // Swap maximum of 1000 DAI to obtain exactly 0.01 WBTC from DAI/WETH and WETH/WBTC pools with 0.3% fee
    // - Swap DAI to WETH on pool with 0.3% fee
    // - Swap WETH to WBTC on pool with 0.3% fee
    // - Send WBTC from Uniswap V3 to this contract
    // NOTE: WBTC has 8 decimals
    function test_swapExactOutput() public {
        
        bytes memory path;
        uint256 amountIn = 0;
        path = abi.encodePacked(DAI, uint24(POOL_FEE), WETH, uint24(POOL_FEE), WBTC);
        amountIn = Router.exactOutput(
            ISwapRouter.ExactOutputParams({
                tokenIn: DAI,
                tokenOut: WBTC,
                fee: POOL_FEE,
                recipient: address(this),
                amountOut: 0.01 * 1e8,
                amountInMaximum: 1000 * 1e18,
                sqrtPriceLimitX96: 0
            })
        );

        console2.log("DAI amount in %e", amountIn);
        assertGt(amountIn, 0);
        assertLe(amountIn, 1000 * 1e18);
        assertEq(wbtc.balanceOf(address(this)), 0.01 * 1e8);
    }   


contract UniswapV3FactoryTest is Test {
    IUniswapV3Factory private factory = IUniswapV3Factory(UNISWAP_V3_FACTORY);
    // 3000 = 0.3%
    //  100 = 0.01%
    uint24 private constant POOL_FEE = 100;
    ERC20 private tokenA;
    ERC20 private tokenB;

    function setUp() public {
        tokenA = new ERC20("A", "A", 18);
        tokenB = new ERC20("B", "B", 18);
    }

    // Exercise 1 - Get the address of DAI/USDC (0.1% fee) pool
    function test_getPool() public {
        address pool = factory.getPool(DAI, USDC, 100);
        assertEq(pool, UNISWAP_V3_POOL_DAI_USDC_100);
    }

    // Exercise 2 - Deploy a new pool with tokenA and tokenB, 0.1% fee
    function test_createPool() public {

        address pool;

        (address token0, address token1) = address(tokenA) <= address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        assertEq(IUniswapV3Pool(pool).token0(), token0);
        assertEq(IUniswapV3Pool(pool).token1(), token1);
        assertEq(IUniswapV3Pool(pool).fee(), POOL_FEE);
    }
}
}