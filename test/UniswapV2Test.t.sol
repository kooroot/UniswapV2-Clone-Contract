// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";
import "../src/UniswapV2Router.sol";
import "../src/WETH.sol";
import "../src/TestToken.sol";

contract UniswapV2Test is Test {
    UniswapV2Factory public factory;
    UniswapV2Router public router;
    WETH public weth;
    TestToken public tokenA;
    TestToken public tokenB;

    address public user1 = address(1);
    address public user2 = address(2);
    address public owner = address(this);

    function setUp() public {
        // Deploy the contracts
        factory = new UniswapV2Factory(owner);
        weth = new WETH();
        router = new UniswapV2Router(address(factory), address(weth));
        
        // Create test tokens with reasonable supply
        tokenA = new TestToken("Token A", "TKNA", 100_000);
        tokenB = new TestToken("Token B", "TKNB", 100_000);
        
        // 토큰 초기 분배 로그
        console.log("Initial tokenA supply:", tokenA.totalSupply());
        console.log("Initial tokenB supply:", tokenB.totalSupply());
        
        // Give some tokens to users - 각 10,000씩 분배
        tokenA.transfer(user1, 10_000 * 10**18);
        tokenB.transfer(user1, 10_000 * 10**18);
        tokenA.transfer(user2, 10_000 * 10**18);
        tokenB.transfer(user2, 10_000 * 10**18);
        
        // 사용자별 잔액 로그
        console.log("User1 tokenA balance:", tokenA.balanceOf(user1));
        console.log("User1 tokenB balance:", tokenB.balanceOf(user1));
        console.log("User2 tokenA balance:", tokenA.balanceOf(user2));
        console.log("User2 tokenB balance:", tokenB.balanceOf(user2));
        
        // Give some ETH to users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        console.log("User1 ETH balance:", user1.balance);
        console.log("User2 ETH balance:", user2.balance);
    }

    function testCreatePair() public {
        // Create a new pair
        factory.createPair(address(tokenA), address(tokenB));
        
        // Check if the pair was created
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        assertTrue(pairAddress != address(0), "Pair not created");
        
        // Verify pair's tokens
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        assertEq(pair.token0(), address(tokenA) < address(tokenB) ? address(tokenA) : address(tokenB), "Token0 mismatch");
        assertEq(pair.token1(), address(tokenA) < address(tokenB) ? address(tokenB) : address(tokenA), "Token1 mismatch");
        
        console.log("Pair created successfully at:", pairAddress);
        console.log("Token0:", pair.token0());
        console.log("Token1:", pair.token1());
    }

    function testAddLiquiditySimple() public {
        // 1. factory를 통해 pair 생성
        factory.createPair(address(tokenA), address(tokenB));
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        console.log("Pair address:", pairAddress);
        
        // 2. 직접 토큰 전송 (Router 사용 없이)
        vm.startPrank(user1);
        
        // 먼저 토큰 승인 (일단 Router용)
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        
        // 3. pair에 직접 토큰 전송
        uint amountA = 1000 * 10**18; // 소량으로 테스트
        uint amountB = 1000 * 10**18; // 소량으로 테스트
        
        tokenA.transfer(pairAddress, amountA);
        tokenB.transfer(pairAddress, amountB);
        
        console.log("Tokens transferred to pair - TokenA:", amountA);
        console.log("Tokens transferred to pair - TokenB:", amountB);
        
        // 4. 직접 mint 호출 (sync 없이)
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // Mint 호출 전 페어의 토큰 잔액 확인
        console.log("Pair TokenA balance before mint:", tokenA.balanceOf(pairAddress));
        console.log("Pair TokenB balance before mint:", tokenB.balanceOf(pairAddress));
        
        pair.mint(user1);
        
        // 5. 유동성 확인
        uint liquidity = pair.balanceOf(user1);
        console.log("User1 liquidity tokens:", liquidity);
        
        // 6. 리저브 확인
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        console.log("Final Reserve0:", reserve0);
        console.log("Final Reserve1:", reserve1);
        
        // 검증
        assertTrue(liquidity > 0, "No liquidity tokens minted");
        assertTrue(reserve0 > 0 && reserve1 > 0, "Reserves not updated");
        
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        // 라우터를 통한 유동성 추가 테스트
        vm.startPrank(user1);
        
        // 1. 토큰 승인
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        console.log("Tokens approved for router");
        
        // 2. 라우터를 통해 유동성 추가
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 * 10**18,  // amountADesired
            1000 * 10**18,  // amountBDesired
            0,  // amountAMin
            0,  // amountBMin
            user1,  // to
            block.timestamp + 3600  // deadline
        );
        
        console.log("Liquidity added via router");
        console.log("Amount A added:", amountA);
        console.log("Amount B added:", amountB);
        console.log("Liquidity tokens received:", liquidity);
        
        // 3. 페어 주소 확인
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // 4. 리저브 확인
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        
        // 검증
        assertTrue(amountA > 0, "No token A added");
        assertTrue(amountB > 0, "No token B added");
        assertTrue(liquidity > 0, "No liquidity tokens minted");
        assertTrue(reserve0 > 0 && reserve1 > 0, "Reserves not updated");
        
        vm.stopPrank();
    }

    function testAddLiquidityETH() public {
        // ETH와 토큰 유동성 추가 테스트
        vm.startPrank(user1);
        
        // 1. 토큰 승인
        tokenA.approve(address(router), type(uint).max);
        console.log("Token A approved for router");
        
        // 2. 라우터를 통해 ETH 유동성 추가
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{value: 1 ether}(
            address(tokenA),
            1000 * 10**18,  // amountTokenDesired
            0,  // amountTokenMin
            0,  // amountETHMin
            user1,  // to
            block.timestamp + 3600  // deadline
        );
        
        console.log("ETH Liquidity added");
        console.log("Amount Token added:", amountToken);
        console.log("Amount ETH added:", amountETH);
        console.log("Liquidity tokens received:", liquidity);
        
        // 3. 페어 주소 확인
        address pairAddress = factory.getPair(address(tokenA), address(weth));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // 4. 리저브 확인
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        console.log("ETH Pair Reserve0:", reserve0);
        console.log("ETH Pair Reserve1:", reserve1);
        
        // 검증
        assertTrue(amountToken > 0, "No token added");
        assertTrue(amountETH > 0, "No ETH added");
        assertTrue(liquidity > 0, "No liquidity tokens minted");
        assertTrue(reserve0 > 0 && reserve1 > 0, "Reserves not updated");
        
        vm.stopPrank();
    }

    function testSwap() public {
        // 스왑 테스트 (먼저 유동성 추가 필요)
        
        // 1. 유동성 추가
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            5000 * 10**18,  // 충분한 유동성 추가
            5000 * 10**18,
            0, 0, user1, block.timestamp + 3600
        );
        
        console.log("Liquidity added for swap test");
        console.log("Initial amounts - A:", amountA);
        console.log("Initial amounts - B:", amountB);
        console.log("Initial amounts - LP:", liquidity);
        vm.stopPrank();
        
        // 2. 다른 사용자가 스왑
        vm.startPrank(user2);
        
        // 초기 잔액 확인
        uint initialBalanceA = tokenA.balanceOf(user2);
        uint initialBalanceB = tokenB.balanceOf(user2);
        console.log("User2 initial balance - TokenA:", initialBalanceA);
        console.log("User2 initial balance - TokenB:", initialBalanceB);
        
        // 스왑을 위한 토큰 승인
        tokenA.approve(address(router), type(uint).max);
        
        // 3. A에서 B로 스왑 
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint amountIn = 100 * 10**18;
        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            0,  // 최소 아웃풋 (슬리피지 없음)
            path,
            user2,
            block.timestamp + 3600
        );
        
        // 최종 잔액 확인
        uint finalBalanceA = tokenA.balanceOf(user2);
        uint finalBalanceB = tokenB.balanceOf(user2);
        console.log("User2 final balance - TokenA:", finalBalanceA);
        console.log("User2 final balance - TokenB:", finalBalanceB);
        console.log("Swap amounts - In:", amounts[0]);
        console.log("Swap amounts - Out:", amounts[1]);
        
        // 검증
        assertTrue(finalBalanceA < initialBalanceA, "TokenA not spent");
        assertTrue(finalBalanceB > initialBalanceB, "TokenB not received");
        assertEq(initialBalanceA - finalBalanceA, amountIn, "Incorrect amount of TokenA spent");
        assertEq(finalBalanceB - initialBalanceB, amounts[1], "Incorrect amount of TokenB received");
        
        vm.stopPrank();
    }

    function testSwapETHForTokens() public {
        // ETH -> 토큰 스왑 테스트
        
        // 1. 먼저 유동성 추가 (ETH + 토큰)
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{value: 5 ether}(
            address(tokenA),
            5000 * 10**18,
            0, 0, user1, block.timestamp + 3600
        );
        
        console.log("ETH-Token liquidity added");
        console.log("Initial amounts - Token:", amountToken);
        console.log("Initial amounts - ETH:", amountETH);
        console.log("Initial amounts - LP:", liquidity);
        vm.stopPrank();
        
        // 2. 다른 사용자가 ETH를 토큰으로 스왑
        vm.startPrank(user2);
        
        // 초기 잔액 확인
        uint initialETHBalance = user2.balance;
        uint initialTokenBalance = tokenA.balanceOf(user2);
        console.log("User2 initial balance - ETH:", initialETHBalance);
        console.log("User2 initial balance - TokenA:", initialTokenBalance);
        
        // ETH에서 토큰으로 스왑 경로 설정
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(tokenA);
        
        // 3. ETH -> 토큰 스왑 실행
        uint amountIn = 1 ether;
        uint[] memory amounts = router.swapExactETHForTokens{value: amountIn}(
            0, // 최소 아웃풋 (슬리피지 없음)
            path,
            user2,
            block.timestamp + 3600
        );
        
        // 최종 잔액 확인
        uint finalETHBalance = user2.balance;
        uint finalTokenBalance = tokenA.balanceOf(user2);
        console.log("User2 final balance - ETH:", finalETHBalance);
        console.log("User2 final balance - TokenA:", finalTokenBalance);
        console.log("Swap amounts - ETH in:", amounts[0]);
        console.log("Swap amounts - Token out:", amounts[1]);
        
        // 검증
        assertTrue(finalETHBalance < initialETHBalance, "ETH not spent");
        assertTrue(finalTokenBalance > initialTokenBalance, "Token not received");
        assertEq(initialETHBalance - finalETHBalance, amountIn, "Incorrect amount of ETH spent");
        assertEq(finalTokenBalance - initialTokenBalance, amounts[1], "Incorrect amount of tokens received");
        
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        // 유동성 제거 테스트
        
        // 1. 먼저 유동성 추가
        vm.startPrank(user1);
        tokenA.approve(address(router), type(uint).max);
        tokenB.approve(address(router), type(uint).max);
        
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 * 10**18,
            1000 * 10**18,
            0, 0, user1, block.timestamp + 3600
        );
        
        console.log("Liquidity added for removal test");
        console.log("Initial amounts - A:", amountA);
        console.log("Initial amounts - B:", amountB);
        console.log("Initial amounts - LP:", liquidity);
        
        // 페어 컨트랙트 가져오기
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // 토큰 잔액 확인
        uint initialTokenABalance = tokenA.balanceOf(user1);
        uint initialTokenBBalance = tokenB.balanceOf(user1);
        console.log("Initial balances - TokenA:", initialTokenABalance);
        console.log("Initial balances - TokenB:", initialTokenBBalance);
        
        // LP 토큰 잔액 확인
        uint lpBalance = pair.balanceOf(user1);
        console.log("LP token balance before approval:", lpBalance);
        
        // 2. LP 토큰 승인
        pair.approve(address(router), lpBalance);
        uint allowance = pair.allowance(user1, address(router));
        console.log("LP token allowance:", allowance);
        
        // 3. 유동성 제거
        (uint removedA, uint removedB) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            lpBalance, // 모든 LP 토큰 제거
            0, 0, // 최소 수량 설정 없음
            user1,
            block.timestamp + 3600
        );
        
        // 최종 잔액 확인
        uint finalTokenABalance = tokenA.balanceOf(user1);
        uint finalTokenBBalance = tokenB.balanceOf(user1);
        uint finalLPBalance = pair.balanceOf(user1);
        
        console.log("Final balances - TokenA:", finalTokenABalance);
        console.log("Final balances - TokenB:", finalTokenBBalance);
        console.log("Final balances - LP:", finalLPBalance);
        console.log("Removed amounts - A:", removedA);
        console.log("Removed amounts - B:", removedB);
        
        // 검증
        assertTrue(finalTokenABalance > initialTokenABalance, "TokenA not returned");
        assertTrue(finalTokenBBalance > initialTokenBBalance, "TokenB not returned");
        assertEq(finalLPBalance, 0, "Not all LP tokens burned");
        
        vm.stopPrank();
    }
}