// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./UniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "forge-std/console.sol"; // 로깅 추가

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;
    
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    
    // 이벤트는 인터페이스에 이미 정의되어 있으므로 여기서 제거
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    
    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }
    
    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }
    
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS");
        
        console.log("Creating pair for tokens:");
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        console.log("Pair created at address:", pair);
        
        // 초기화 호출하기 전에 로그 남기기
        console.log("Initializing pair...");
        UniswapV2Pair(pair).initialize(token0, token1);
        console.log("Pair initialized successfully");
        
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
    
    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }
    
    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}