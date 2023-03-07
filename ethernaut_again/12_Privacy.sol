// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true; // slot 0
    uint256 public ID = block.timestamp; // slot 1
    uint8 private flattening = 10; // slot 2
    uint8 private denomination = 255; // slot 2
    uint16 private awkwardness = uint16(block.timestamp); // slot 2
    bytes32[3] private data; // slot 3

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...
    0x88e5ee0e18c84d4edb0bb16e521e2d50056150aaf4d0d7ab28adff4afc911649
    0x056150aaf4d0d7ab28adff4afc911649
      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}
