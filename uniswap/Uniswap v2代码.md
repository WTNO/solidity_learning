# 1. 组成
## uniswap-v2-core
* UniswapV2Factory：工厂合约，用于创建Pair合约（以及设置协议手续费接收地址）
* UniswapV2Pair：Pair（交易对）合约，定义和交易有关的几个最基础方法，如swap/mint/burn，价格预言机等功能，其本身是一个ERC20合约，继承UniswapV2ERC20
* UniswapV2ERC20：实现ERC20标准方法
## uniswap-v2-periphery
* UniswapV2Router02：最新版的路由合约，相比UniswapV2Router01增加了对FeeOnTransfer代币的支持；实现Uniswap v2最常用的接口，比如添加/移除流动性，使用代币A交换代币B，使用ETH交换代币等
* UniswapV1Router01：旧版本Router实现，与Router02类似，但不支持FeeOnTransferTokens，目前已不使用

# 2. uniswap-v2-core
## 2.1 UniswapV2Factory
1. 首先将token0 token1按照顺序排序，确保token0字面地址小于token1。
2. 接着使用assembly + create2创建合约。create2主要用于创建确定性的交易对合约地址，目的是根据两个代币地址直接计算pair地址，而无需调用链上合约查询。对于同一个交易对的两种代币，其salt值应该一样；这里很容易想到应该使用交易对的两种代币地址，我们希望提供A/B地址的时候可以直接算出pair(A,B)，而两个地址又受顺序影响，因此在合约开始时先对两种代币进行排序

    > assembly可以在Solidity中使用Yul语言直接操作EVM，是较底层的操作方法。实际上在最新版的EMV中，已经直接支持给new方法传递salt参数,如下所示：
    ```java
    pair = new UniswapV2Pair{salt: salt}();
    ```

## 2.2 UniswapV2ERC20
### &emsp;&emsp;这个合约主要定义了UniswapV2的ERC20标准实现，代码比较简单。前面已经学习，这里主要关注permit方法。
1. permit方法实现的就是白皮书2.5节中介绍的“Meta transactions for pool shares 元交易”功能。
2. EIP-712定义了离线签名的规范，即digest的格式定义，用户签名的内容是其（owner）授权（approve）某个合约（spender）可以在截止时间（deadline）之前花掉一定数量（value）的代币（Pair流动性代币）。
3. 应用（periphery合约）拿着签名的原始信息和签名后生成的v, r, s，可以调用Pair合约的permit方法获得授权，permit方法使用ecrecover还原出签名地址为代币所有人，验证通过则批准授权。

## 2.3 UniswapV2Pair
### &emsp;&emsp;Pair合约主要实现了三个方法：mint（添加流动性）、burn（移除流动性）、swap（兑换）。<font color="red">（注意要区分ERC20合约中的_mint和_burn）</font>
### 1. mint：本方法实现添加流动性功能。
* 首先getReserves()获取两种代币的缓存余额。在白皮书中提到，__保存缓存余额是为了防止攻击者操控价格预言机。 此处还用于计算协议手续费，并通过当前余额与缓存余额相减获得转账的代币数量。__
* _mintFee用于计算协议手续费，计算公式参考<a href="https://hackmd.io/@adshao/HkZwPZNf9#24-Protocol-fee-%E5%8D%8F%E8%AE%AE%E6%89%8B%E7%BB%AD%E8%B4%B9">白皮书</a>。
* mint方法中判断，如果是首次提供该交易对的流动性，则根据根号xy生成流动性代币，并销毁其中的MINIMUM_LIQUIDITY（即1000wei）；否则根据转入的代币价值与当前流动性价值比例铸造流动性代币。

### 2. burn





