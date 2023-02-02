// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ControlStream {
    function ifElseTest(uint256 _number) public pure returns(bool){
        if(_number > 100){
            return(true);
        }
        return(false);
    }

    function forTest(uint rank) public pure returns(uint) {
        if (rank <= 2) return 1;
        uint sum;
        uint num1 = 1;
        uint num2 = 1;
        for (uint i = 0; i < rank - 2; i++) {
            sum = num1 + num2;
            num1 = num2;
            num2 = sum;
        }
        return sum;
    }

    function whileTest(uint rank) public pure returns(uint) {
        if (rank <= 2) return 1;
        uint sum;
        uint num1 = 1;
        uint num2 = 1;
        uint i;
        while(i++ < rank - 2) {
            sum = num1 + num2;
            num1 = num2;
            num2 = sum;
        }
        return sum;
    }

    function doWhileTest(uint rank) public pure returns(uint) {
        if (rank <= 2) return 1;
        uint sum;
        uint num1 = 1;
        uint num2 = 1;
        uint i;
        do {
            sum = num1 + num2;
            num1 = num2;
            num2 = sum;
        } while (++i < rank - 2);
        
        return sum;
    }

    // 三元运算符
    function ternaryTest(uint256 x, uint256 y) public pure returns(uint256){
        // return the max of x and y
        return x >= y ? x: y; 
    }

    // 归并排序
    function sortTest(uint[] memory array) public pure returns(uint[] memory) {
        uint[] memory arr = array;
        sort(arr);
        return arr;
    }

    function sort(uint[] memory array) internal pure {
        sort(array, 0, array.length - 1);
    }

    function sort(uint[] memory array, uint low, uint high) internal pure {
        if (low != high) {
            uint mid = (low + high) / 2;
            sort(array, low, mid);
            sort(array, mid + 1, high);
            merge(array, low, mid, high);
        }
    }

    function merge(uint[] memory array, uint low, uint mid, uint high) internal pure {
        uint[] memory help = new uint[](high - low + 1);

        uint i = 0;
        uint idx1 = low;
        uint idx2 = mid + 1;

        while (idx1 <= mid && idx2 <= high) {
            help[i++] = array[idx1] > array[idx2] ? array[idx2++] : array[idx1++];
        }

        while (idx1 <= mid) {
            help[i++] = array[idx1++];
        }

        while (idx2 <= high) {
            help[i++] = array[idx2++];
        }

        for (uint j = 0; j < help.length; j++) {
            array[low++] = help[j];
        }
    }

    // 问题复现：如何将上面的排序修改为变长数组，目前作用域有问题(解决)
    uint[] arrSwap;
    function swapTest(uint[] memory arr) public pure returns(uint[] memory) {
        swap(arr);
        return arr;
    }

    function swap(uint[] memory array) public pure {
        uint temp = array[0];
        array[0] = array[1];
        array[1] = temp;
    }
}