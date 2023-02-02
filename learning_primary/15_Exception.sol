// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error TransferNotOwner(); // 自定义error,0.8.4版本新增

error TransferNotOwner1(address sender); // 自定义的带参数的error

contract Exception {
    // 一组映射，记录每个TokenId的Owner
    mapping(uint256 => address) private _owners;

    // 在执行当中，error必须搭配revert（回退）命令使用。
    function transferOwner1(uint256 tokenId, address newOwner) public {
        if(_owners[tokenId] != msg.sender){
            // revert TransferNotOwner();
            revert TransferNotOwner1(msg.sender);
        }
        _owners[tokenId] = newOwner;
    }

    // 0.8版本之前常用require抛出异常
    // 唯一的缺点就是gas随着描述异常的字符串长度增加，比error命令要高。
    // 使用方法：require(检查条件，"异常的描述")
    function transferOwner2(uint256 tokenId, address newOwner) public {
        require(_owners[tokenId] == msg.sender, "Transfer Not Owner");
        _owners[tokenId] = newOwner;
    }

    // 断言Assert
    // 一般用于程序员写程序debug，因为它不能解释抛出异常的原因（比require少个字符串）
    function transferOwner3(uint256 tokenId, address newOwner) public {
        assert(_owners[tokenId] == msg.sender);
        _owners[tokenId] = newOwner;
    }
}