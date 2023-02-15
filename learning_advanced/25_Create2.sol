// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * 在合约中创建新合约
 * 方法二：create2
 * Contract x = new Contract{salt: _salt, value: _value}(params) 多了一个salt参数
 * CREATE2 操作码可以在智能合约部署在以太坊网络之前就能预测合约的地址
 * 新地址 = hash("0xFF",创建者地址, salt, bytecode)
 * 0xFF：一个常数，避免和CREATE冲突
 * salt（盐）：一个创建者给定的数值
 * 待部署合约的字节码（bytecode）:keccak256(type(Pair).creationCode)
 *
 * 应用场景：
 * 1.交易所为新用户预留创建钱包合约地址。
 *
 */
contract Create2 {
    mapping(address => mapping(address => address)) public getPair; // 通过两个代币地址查Pair地址
    address[] public allPairs; // 保存所有Pair地址
    function createPair2(address tokenA, address tokenB) external returns (address pairAddr) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES"); //避免tokenA和tokenB相同产生的冲突
        //将tokenA和tokenB按大小排序(为什么？)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); 
        // 用tokenA和tokenB地址计算salt
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // 创建新合约
        Pair pair = new Pair{salt: salt}();
        // 调用新合约的initialize方法
        pair.initialize(tokenA, tokenB);
        // 更新地址map
        pairAddr = address(pair); // address(合约对象)是啥写法？？
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }

    // 提前计算pair合约地址
    function calculateAddr(address tokenA, address tokenB) public view returns(address predictedAddress){
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        // 计算用tokenA和tokenB地址计算salt
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); //将tokenA和tokenB按大小排序
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // 计算合约地址方法 hash()
        predictedAddress = address(uint160(uint(
            keccak256(
                abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(type(Pair).creationCode))
            )
        )));
    }
}

contract Pair{
    address public factory; // 工厂合约地址
    address public token0; // 代币1
    address public token1; // 代币2

    constructor() payable {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
}

