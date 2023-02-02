// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ArrayType {
    /********************数组类型**********************/
    // 可变数组
    uint[] numberArray_;
    // bytes比较特殊，是数组，但是不用加[]。不能用byte[]声明单字节数组，可以使用bytes或bytes1[]。
    bytes byteArrays_; 

    // 固定长度数组(内存数组的长度在创建后是固定的。)
    uint[8] numberArray;
    // 在gas上，bytes比bytes1[]便宜。因为bytes1[]在memory中要增加31个字节进行填充，
    // 会产生额外的gas。但是在storage中，由于内存紧密打包，不存在字节填充。
    bytes1[8] byteArray;

    function dynamicArrayTest() public pure {
        // 对于<memory>修饰的<动态>数组，可以使用new操作符，但是必须声明长度，且声明后不能改变
        uint[] memory numberArray1 = new uint[](4);
        bytes memory byteArray1 = new bytes(8);
        numberArray1[0] = 1; // 1.状态变量不能使用memory修饰； 2.局部变量创建后不使用会报错
        byteArray1[0] = 0xad;
        byteArray1[1] = 0x4d;

        // 如果创建的是动态数组，你需要一个一个元素的赋值。(不能如下赋值)
        // numberArray1 = [uint(0), 1, 2, 3];
    }

    // 数组字面常数
    function f() public pure {
        // solidity中如果一个值没有指定type的话，默认就是最小单位的该type，所以这里int的默认最小单位是uint8，与函数g的入参不符
        // g([1, 2, 3]);

        // 第一个元素指定了是uint类型了，所以以第一个元素为准
        g([uint(1), 2, 3]);
        g([1, uint256(2), 3]); // uint=uint256，且不是必须对第一个元素强转
    }

    function g(uint[3] memory) public pure{}

    // 数组成员
    function arrayMember() public returns(uint, uint[] memory) {
        uint[2] memory a = [uint(1),2];
        // uint[] memory array = a; // 不能这么写？
        numberArray_ = a;
        numberArray_.push();
        numberArray_.push(1);
        numberArray_.push(2);
        numberArray_.push(3);
        numberArray_.push(4);
        numberArray_.pop();
        return(numberArray_.length, numberArray_);
    }
}

pragma solidity ^0.8.4;
contract StructType {
    /********************结构体**********************/
    struct Student{
        uint256 id;
        uint256 score; 
    }

    Student student;

    // 给结构体赋值
    // 方法一:在函数中创建一个storage的struct引用
    function initStudent() external {
        Student storage _student = student;
        _student.id = 1;
        _student.score = 88;
    }

    // 方法二:直接引用状态变量的struct
    function initStudent1() external {
        student.id = 2;
        student.score = 66;
    }
}