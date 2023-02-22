// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 这个合约的制作者非常小心的保护了敏感区域的 storage.
 * 解开这个合约来完成这一关.
 *
 *
 *
 */
contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}

/**
 * https://learnblockchain.cn/docs/solidity/internals/layout_in_storage.html
 * 
 * slot 0:
 * locked 占1个字节，剩余的3个字节留空
 * 
 * slot 1:
 * ID 占4个字节
 * 
 * slot 2:
 * flatterning占1个字节， denomination占1个字节， awkardness占2个字节。
 * 
 * slot 3, 4, 5:
 * data[0]，data[1],data[2]
 */
contract Unlock {
    function unlock(Privacy _address, bytes16 num) public {
        _address.unlock(num);
    }
}
