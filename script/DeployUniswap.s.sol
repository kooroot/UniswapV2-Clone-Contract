// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router.sol";
import "../src/WETH.sol";
import "../src/TestToken.sol";

contract DeployUniswap is Script {
    function run() public {
        address testaddr = 0xa2AbF7779EA7Dd5087af63AA02982CD9167a9D8A;
        
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
        tokenA.mint(msg.sender, 10_000 * 10**18);
        console.log("Token A deployed at:", address(tokenA));
        tokenA.transfer(address(testaddr), 100 * 10**18);
        console.log("Token A transferred to testaddr", tokenA.balanceOf(testaddr));
        console.log("Token A balance:", tokenA.balanceOf(msg.sender));

        TestToken tokenB = new TestToken("Token B", "TKNB", 1_000_000);
        tokenB.mint(msg.sender, 10_000 * 10**18);
        console.log("Token B deployed at:", address(tokenB));
        tokenB.transfer(address(testaddr), 100 * 10**18);
        console.log("Token B transferred to testaddr", tokenB.balanceOf(testaddr));
        console.log("Token B balance:", tokenB.balanceOf(msg.sender));

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
        router.addLiquidityWETH{value: 10 ether}(
            address(tokenA),
            1000 * 10**18,
            0,
            0,
            msg.sender,
            block.timestamp + 3600
        );
        console.log("Added liquidity to TokenA-WETH pair");

        router.addLiquidityWETH{value: 10 ether}(
            address(tokenB),
            1000 * 10**18,      
            0,
            0,
            msg.sender,
            block.timestamp + 3600
        );
        console.log("Added liquidity to TokenB-WETH pair");

        (bool sent, ) = testaddr.call{value: 1 ether}("");
        require(sent, "Failed to send Ether");
        console.log("Transferred 1 ether to testaddr");

        vm.stopBroadcast();
    }
}