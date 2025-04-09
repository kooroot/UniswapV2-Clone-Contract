// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router.sol";
import "../src/WETH.sol";
import "../src/TestToken.sol";

contract DeployUniswap is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy WETH
        WETH weth = new WETH();
        console.log("WETH deployed at:", address(weth));

        // Deploy Factory
        UniswapV2Factory factory = new UniswapV2Factory(msg.sender);
        console.log("Factory deployed at:", address(factory));

        // Deploy Router
        UniswapV2Router router = new UniswapV2Router(address(factory), address(weth));
        console.log("Router deployed at:", address(router));

        // Deploy Test Tokens
        TestToken tokenA = new TestToken("Token A", "TKNA", 1_000_000);
        console.log("Token A deployed at:", address(tokenA));

        TestToken tokenB = new TestToken("Token B", "TKNB", 1_000_000);
        console.log("Token B deployed at:", address(tokenB));

        // Create initial pair and add liquidity
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);

        // Add liquidity for token pair
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 * 10**18,
            1000 * 10**18,
            0,
            0,
            msg.sender,
            block.timestamp + 3600
        );
        console.log("Added liquidity to TokenA-TokenB pair");

        // Add liquidity for ETH pair
        router.addLiquidityETH{value: 10 ether}(
            address(tokenA),
            1000 * 10**18,
            0,
            0,
            msg.sender,
            block.timestamp + 3600
        );
        console.log("Added liquidity to TokenA-ETH pair");

        vm.stopBroadcast();
    }
}