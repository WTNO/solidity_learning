// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {OtherContract} from './21_CallOtherContract.sol';

/**
 * 推荐使用call通过触发fallback或receive函数发送ETH；
 * 不推荐用call来调用另一个合约，推荐的方法仍是声明合约变量后调用函数；
 * 但是不知道对方合约的源代码或ABI没法生成合约变量时，我们仍可以通过call调用对方合约的函数。
 */
contract Call {
    event Response(bool success, bytes data);

    function callSetX(address payable _address, uint256 _x) public payable {
        (bool success, bytes memory data) = _address.call{value: msg.value}(abi.encodeWithSignature("setX(uint256)", _x));
        emit Response(success, data);
    }

    function callGetX(address _address) public returns(uint256) {
        (bool success, bytes memory data) = _address.call(abi.encodeWithSignature("getX()"));
        emit Response(success, data);
        return abi.decode(data, (uint256)); // TODO:测试没显示返回值
    }

    // 调用不存在的函数仍然能返回success，因为被调用合约有fallback函数
    // 给call输入的函数不存在于目标合约，那么目标合约的fallback函数会被触发。注意这里不同于接受ETH时调用fallback。
    function callNotExist(address _address) public {
        (bool success, bytes memory data) = _address.call(abi.encodeWithSignature("ngf()"));
        emit Response(success, data);
    }
}