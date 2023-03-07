// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {

  address public solver;

  constructor() {}

  function setSolver(address _solver) public {
    solver = _solver;
  }

  /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
  */
}

/* 构造 开始*/

// PUSH1 code_length
// PUSH1 code_offset
// PUSH1 memory_pos
// CODECOPY

// memory[memory_pos:memory_pos+code_length] =
// address(this).code[code_offset:code_offset+code_length]

// PUSH1 code_length
// PUSH1 memory_pos
// RETURN

// return memory[memory_pos:memory_pos+code_length]
/* 构造结束 */

/* 执行开始,返回42 = 2A */
// PUSH1 value
// PUSH1 memory_pos
// MSTORE

// memory[memory_pos:memory_pos+32] = value

// PUSH1 value_length
// PUSH1 memory_pos
// RETURN

// return memory[memory_pos:memory_pos+value_length]
/* 执行结束 */

// 转换下：
// PUSH1 0x0a // 10字节大小
// PUSH1 0x0c // 12字节开始(是运行态代码相对于整体（初始化+运行态）的偏移,初始化12个字节)
// PUSH1 0x40 // memory_pos 从40及以后开始
// CODECOPY

// memory[memory_pos:memory_pos+code_length] =
// address(this).code[code_offset:code_offset+code_length]

// PUSH1 0x0a // 10字节大小
// PUSH1 0x40 // memory_pos 从40及以后开始
// RETURN

// return memory[memory_pos:memory_pos+code_length]
/* 构造结束 */
/* 执行开始,返回42 = 2A */

// PUSH1 0x2A 
// PUSH1 0x40 // 存储在0x40的位置
// MSTORE

// memory[memory_pos:memory_pos+32] = value

// PUSH1 0x20 // 0x20=32即uint256的字节数
// PUSH1 0x40
// RETURN

// 0x600a600c604039600a6040f3602a60405260206040f3
// 0x600a600c602039600a6020f3602a60605260206060f3

// web3.eth.sendTransaction({from:player, data:"0x600a600c604039600a6040f3602a60405260206040f3"}) // 交易没有接受方，自动被识别为部署合约
// await web3.eth.call({from:player, to:"0x2C439290497f4fb14A756f2d76F380b0C4F1a100"})
// contract.setSolver("0x2C439290497f4fb14A756f2d76F380b0C4F1a100")