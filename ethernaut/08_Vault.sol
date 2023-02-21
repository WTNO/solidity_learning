// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 打开 vault 来通过这一关!
// web3.eth.getStorageAt("0x59fBb7027AD90E030E5333282Fb18CC465C2C497", 0)
// 使用web3.js
// web3.eth.getStorageAt(address, position [, defaultBlock] [, callback])
contract Vault {
  bool public locked;
  bytes32 private password;

  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}