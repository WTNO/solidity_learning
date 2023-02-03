// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * 在solidity中，try-catch只能被用于external函数或创建合约时constructor（被视为external函数）的调用。
 * 语法：
 *      try externalContract.f() {
 *          // call成功的情况下 运行一些代码
 *      } catch {
 *          // call失败的情况下 运行一些代码
 *      }
 *
 *      有返回值时：
 *      try externalContract.f() returns(returnType val){
 *          // call成功的情况下 运行一些代码
 *      } catch {
 *          // call失败的情况下 运行一些代码
 *      }
 *
 *      支持捕获特殊的异常原因：
 *      try externalContract.f() returns(returnType){
 *          // call成功的情况下 运行一些代码
 *      } catch Error(string memory reason) {
 *          // 捕获失败的 revert() 和 require()
 *      } catch (bytes memory reason) {
 *          // 捕获失败的 assert()
 *      }
 * externalContract.f()是某个外部合约的函数调用，try模块在调用成功的情况下运行，而catch模块则在调用失败时运行。
 * 可以使用this.f()来替代externalContract.f()
 */
contract TryCatch {
    // 成功event
    event SuccessEvent();
    // 失败的revert() 和 require()
    event CatchEvent(string message);
    // 失败的assert()
    event CatchByte(bytes data);

    OnlyEven even;
    constructor() {
        even = new OnlyEven(2);
    }
    
    function test(uint num) external returns(bool) {
        try even.onlyEven(num) returns(bool result) {
            emit SuccessEvent();
            return result;
        } catch Error(string memory reason) {
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            emit CatchByte(reason);
        }
    }

    // 在创建新合约中使用try-catch （合约创建被视为external call）
    // executeNew(0)会失败并释放`CatchEvent`
    // executeNew(1)会失败并释放`CatchByte`
    // executeNew(2)会成功并释放`SuccessEvent`
    function executeNew(uint a) external returns (bool success) {
        try new OnlyEven(a) returns(OnlyEven _even){
            // call成功的情况下
            emit SuccessEvent();
            success = _even.onlyEven(a);
        } catch Error(string memory reason) {
            // catch失败的 revert() 和 require()
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            // catch失败的 assert()
            emit CatchByte(reason);
        }
    }
}

// 无法部署，只能new
contract OnlyEven {
    constructor(uint a){
        require(a != 0, "invalid number");
        assert(a != 1);
    }

    function onlyEven(uint256 b) external pure returns(bool success){
        // 输入奇数时revert
        require(b % 2 == 0, "Ups! Reverting");
        success = true;
    }
}