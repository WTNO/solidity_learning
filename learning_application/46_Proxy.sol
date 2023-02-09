// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 代理合约，调用方
contract Proxy {
    // 逻辑合约地址。implementation合约同一个位置的状态变量类型必须和Proxy合约的相同，不然会报错。
    address public implementation; 

    /**
     * @dev 初始化逻辑合约地址
     */
    constructor(address implementation_){
        implementation = implementation_;
    }

    /**
     * @dev 回调函数，将本合约的调用委托给 `implementation` 合约
     * 通过assembly，让回调函数也能有返回值
     */
    fallback() external payable {
        address _implementation = implementation;
        // 使用内联汇编的原因：让本来不能有返回值的回调函数有了返回值
        assembly {
            // 将msg.data拷贝到内存里
            // calldatacopy(to, from, size)操作码的参数: 内存起始位置，calldata起始位置，calldata长度
            calldatacopy(0, 0, calldatasize())
    
            // 利用delegatecall(g, a, in, insize, out, outsize)调用implementation合约
            // delegatecall操作码的参数：gas, 目标合约地址，input mem起始位置，input mem长度，output area mem起始位置，output area mem长度
            // output area起始位置和长度未知，所以设为0
            // delegatecall成功返回1，失败返回0
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
    
            // 将return data拷贝到内存
            // returndatacopy(to, from, size)操作码的参数：内存起始位置，returndata起始位置，returndata长度
            returndatacopy(0, 0, returndatasize())
    
            switch result
            // 如果delegate call失败，revert
            case 0 {
                revert(0, returndatasize())
            }
            // 如果delegate call成功，返回mem起始位置为0，长度为returndatasize()的数据（格式为bytes）
            default {
                return(0, returndatasize())
            }
        }
    }
}