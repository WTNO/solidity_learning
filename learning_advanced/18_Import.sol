// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 通过文件相对位置import
import '../learning_orimary/Exception.sol';
// 通过网址引用
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol';
// 通过全局符号导入特定的合约
import {Selector} from './29_Selector.sol';
//还可以通过npm的目录导入
import '@openzeppelin/contracts/access/Ownable.sol';

contract Import {
    // 测试网址引用
    using Strings for uint256;
    function getString1(uint256 _number) public pure returns(string memory){
        // 库函数会自动添加为uint256型变量的成员
        return _number.toHexString();
    }

    // 声明Selector变量
    Selector selector = new Selector();
    // 测试全局符号导入
    function SelectorTest() public view returns(bytes4 mSelector) {
        bytes4 result = selector.mintSelector();
        return result;
    }
}