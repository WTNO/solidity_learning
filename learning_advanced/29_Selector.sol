// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Selector {
    // event 返回msg.data
    event Log(bytes data);

    // 参数0x2c44b726ADF1963cA47Af88B284C06f30380fC78
    // calldata:0xbb29998e0000000000000000000000002c44b726adf1963ca47af88b284c06f30380fc78
    // 前4个字节 -> 函数选择器selector：0xbb29998e
    // 后32个字节 -> 输入的参数：0x0000000000000000000000002c44b726adf1963ca47af88b284c06f30380fc78
    function test(address to) external{
        emit Log(msg.data);
    }

    // method id
    // 上面方法的method id：0xbb29998e
    // 当selector与method id相匹配时,即表示调用该函数
    // 函数签名：指的是函数名（逗号分隔的参数类型)，上面的函数签名是mint(address)
    function mintSelector() external pure returns(bytes4 mSelector){
        return bytes4(keccak256("transfer(address,uint256)"));
    }

    // 通过abi.encodeWithSelector(method id, params)调用test方法
    function callWithSignature() external returns(bool, bytes memory){
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(0xbb29998e, 0x2c44b726ADF1963cA47Af88B284C06f30380fC78));
        return(success, data);
    }

    mapping(address => uint) public balanceOf;
    event Transfer(address from, address to, uint amount);
    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // 返回false
    function transferTest() external returns(bool, bytes memory) {
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(0xa9059cbb, address(0), uint256(100)));
        return(success, data);
    }

}