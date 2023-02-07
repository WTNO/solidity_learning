// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./34_ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Random is ERC721, VRFConsumerBase {
    // NFT相关
    // 总供给
    uint256 public totalSupply = 100;
    // 用于计算可供mint的tokenId
    uint256[100] public ids;
    // 已mint数量
    uint256 public mintCount;
    // chainlink VRF相关
    // VRF唯一标识符
    bytes32 internal keyHash;
    // VRF手续费
    uint256 internal fee;
    // 记录VRF申请标识对应的mint地址
    mapping(bytes32 => address) public requestToSender;

    /**
     * 使用chainlink VRF，构造函数需要继承 VRFConsumerBase
     * 不同链参数填的不一样
     * 网络: Rinkeby测试网
     * Chainlink VRF Coordinator 地址: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK 代币地址: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
        ERC721("WTF Random", "WTF")
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; // 0.1 LINK (VRF使用费，Rinkeby测试网)
    }

    /**
     * 链上伪随机数生成
     * keccak256(abi.encodePacked()中填上一些链上的全局变量/自定义变量
     * 返回时转换成uint256类型
     */
    function getRandomOnchain() public view returns (uint256) {
        // remix跑blockhash会报错
        bytes32 randomBytes = keccak256(
            abi.encodePacked(
                block.number,
                msg.sender,
                blockhash(block.timestamp - 1)
            )
        );
        return uint256(randomBytes);
    }

    // 利用链上伪随机数铸造NFT
    function mintRandomOnchain() public {
        uint256 _tokenId = pickRandomUniqueId(getRandomOnchain()); // 利用链上随机数生成tokenId
        _mint(msg.sender, _tokenId);
    }

    /**
     * 调用VRF获取随机数，并mintNFT
     * 要调用requestRandomness()函数获取，消耗随机数的逻辑写在VRF的回调函数fulfillRandomness()中
     * 调用前，把LINK代币转到本合约里
     */
    function mintRandomVRF() public returns (bytes32 requestId) {
        // 检查合约中LINK余额
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        // 调用requestRandomness获取随机数
        requestId = requestRandomness(keyHash, fee);
        requestToSender[requestId] = msg.sender;
        return requestId;
    }

    /**
     * VRF的回调函数，由VRF Coordinator调用
     * 消耗随机数的逻辑写在本函数中
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // 从requestToSender中获取minter用户地址
        address sender = requestToSender[requestId];
        // 利用VRF返回的随机数生成tokenId
        uint256 tokenId = pickRandomUniqueId(randomness);
        _mint(sender, tokenId);
    }

    /**
     * 输入uint256数字，返回一个可以mint的tokenId
     * 算法过程可理解为：totalSupply个空杯子（0初始化的ids）排成一排，每个杯子旁边放一个球，编号为[0, totalSupply - 1]。
     * 每次从场上随机拿走一个球（球可能在杯子旁边，这是初始状态；也可能是在杯子里，说明杯子旁边的球已经被拿走过，则此时新的球从末尾被放到了杯子里）
     * 再把末尾的一个球（依然是可能在杯子里也可能在杯子旁边）放进被拿走的球的杯子里，循环totalSupply次。相比传统的随机排列，省去了初始化ids[]的gas。
     */
    function pickRandomUniqueId(uint256 random) private returns (uint256 tokenId) {
        // 可mint数量
        uint256 len = totalSupply - mintCount++;
        // 所有tokenId被mint完了
        require(len > 0, "mint close");
        // 获取链上随机数
        uint256 randomIndex = random % len;

        //随机数取模，得到tokenId，作为数组下标，同时记录value为len-1，如果取模得到的值已存在，则tokenId取该数组下标的value
        // 获取tokenId
        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        // 更新ids 列表
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1];
        // 删除最后一个元素，能返还gas
        ids[len - 1] = 0;
    }
}
