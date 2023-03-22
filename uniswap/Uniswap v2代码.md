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

## 2.3 <a href="https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol">UniswapV2Pair</a>
### &emsp;&emsp;Pair合约主要实现了三个方法：mint（添加流动性）、burn（移除流动性）、swap（兑换）。<font color="red">（注意要区分ERC20合约中的_mint和_burn）</font>
### 1. mint：本方法实现添加流动性功能。
```java
function mint(address to) external lock returns (uint liquidity) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint amount0 = balance0.sub(_reserve0);
    uint amount1 = balance1.sub(_reserve1);

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas节省，必须在这里定义，因为 totalSupply 可以在 _mintFee 中更新
    if (_totalSupply == 0) {
        liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
        _mint(address(0), MINIMUM_LIQUIDITY); // 永久锁定第一个 MINIMUM_LIQUIDITY 代币
    } else {
        liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
    }
    require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date，重新计算K
    emit Mint(msg.sender, amount0, amount1);
}
```
* 首先getReserves()获取两种代币的缓存余额。在白皮书中提到，__保存缓存余额是为了防止攻击者操控价格预言机。 此处还用于计算协议手续费，并通过当前余额与缓存余额相减获得转账的代币数量。__
* _mintFee用于计算协议手续费，计算公式参考<a href="https://hackmd.io/@adshao/HkZwPZNf9#24-Protocol-fee-%E5%8D%8F%E8%AE%AE%E6%89%8B%E7%BB%AD%E8%B4%B9">白皮书</a>。
* mint方法中判断，如果是首次提供该交易对的流动性，则根据根号xy生成流动性代币，并销毁其中的MINIMUM_LIQUIDITY（即1000wei）；否则根据转入的代币价值与当前流动性价值比例铸造流动性代币。
* `if (_totalSupply == 0)`意思是首次添加流动性时：
  $$liquidity=\sqrt{x·y}-L_{min}$$
    > 举个例子：一个Uniswap v2交易对，初始提供100ETH和10,000 token的流动性，获得1000枚LP。
    > 其中，$L_{min}=1000$，是为了防止首次铸币攻击而销毁的固定代币数量。
    > 因此，当前的总流动性代币并不是$1000∗10^{18}$，而是$1000∗10^{18}−1000$。（假设token的精度为$10^{18}$），reserve0为$100∗10^{18}$，reserve1为$10000∗10^{18}$ 。
* else 否则
$$liquidity=min(\frac{amount0·\_totalSupply}{\_reserve0}, \frac{amount1·\_totalSupply}{\_reserve1})$$

### 2. burn：本方法实现移除流动性功能。
```java
function burn(address to) external lock returns (uint amount0, uint amount1) {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    address _token0 = token0;                                // gas savings
    address _token1 = token1;                                // gas savings
    uint balance0 = IERC20(_token0).balanceOf(address(this));
    uint balance1 = IERC20(_token1).balanceOf(address(this));
    uint liquidity = balanceOf[address(this)];

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
    amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
    require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
    _burn(address(this), liquidity);
    _safeTransfer(_token0, to, amount0);
    _safeTransfer(_token1, to, amount1);
    balance0 = IERC20(_token0).balanceOf(address(this));
    balance1 = IERC20(_token1).balanceOf(address(this));

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
    emit Burn(msg.sender, amount0, amount1, to);
}
```
* 与mint类似，burn方法也会先计算协议手续费。
* 参考白皮书，为了节省交易手续费，Uniswap v2只在mint/burn流动性时收取累计的协议手续费。
* 移除流动性后，根据销毁的流动性代币占总量的比例获得对应的两种代币。

### 3. swap：方法实现两种代币的交换（交易）功能。
```java
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
    require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
    (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
    require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

    uint balance0;
    uint balance1;
    { // scope for _token{0,1}, avoids stack too deep errors
    address _token0 = token0;
    address _token1 = token1;
    require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
    // 允许用户在支付费用前先收到并使用代币
    if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
    if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

    // 调用一个可选的用户指定的回调合约。
    if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

    balance0 = IERC20(_token0).balanceOf(address(this));
    balance1 = IERC20(_token1).balanceOf(address(this));
    }
    uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
    uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
    require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
    { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
    uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
    uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
    // 一旦回调完成，Uniswap合约会检查当前代币余额，并且确认其满足k值条件（在扣除手续费后）。
    // 如果当前合约没有足够的余额，整个交易将被回滚。
    require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
    }

    _update(balance0, balance1, _reserve0, _reserve1);
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
}
```
* 为了兼容闪电贷功能，以及不依赖特定代币的transfer方法，整个swap方法并没有类似amountIn的参数，而是通过比较当前余额与缓存余额的差值来得出转入的代币数量。
* 由于在swap方法最后会检查余额（扣掉手续费后）符合k常值函数约束（参考白皮书公式）：
  $$(x_1-0.003·x_{in})·(y_1-0.003·y_{in}) \ge x_0·y_0$$
  因此合约可以先将用户希望获得的代币转出，如果用户之前并没有向合约转入用于交易的代币，则相当于借币（即闪电贷）；如果使用闪电贷，则需要在自定义的uniswapV2Call方法中将借出的代币归还。
* 在swap方法最后会使用缓存余额更新价格预言机所需的累计价格，最后更新缓存余额为当前余额。(具体代码需要结合白皮书看)

# 3. uniswap-v2-periphery
## 3.1 <a href="https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol">UniswapV2Library</a>
### 3.1.1 pairFor
输入工厂地址和两个代币地址，计算这两个代币的交易对地址。
### 3.1.2 quote
将数量为amountA的代币A，按照合约中两种代币余额比例，换算成另一个代币B。此时不考虑手续费，因为仅是计价单位的换算。
$$amountB = amountA * reserveB / reserveA$$
### 3.1.3 getAmountOut
输入一定数量（amountIn）代币A，根据池子中代币余额，能得到多少数量（amountOut）代币B。
> 先回顾白皮书以及core合约中对于swap交换后两种代币的约束：$(x_1-0.003·x_{in})·(y_1-0.003·y_{in}) \ge x_0·y_0$<br/>
> 其中，$x_0$, $y_0$为交换前的两种代币余额，$x_1$, $y_1$为交换后的两种代币余额，$x_0{in}$为输入的代币A数量，因为只提供代币A，因此$y_{in}=0$；$y_{out}$为需要计算的代币B数量。<br/>
> 可以推导出公式如下：
> $$y_{out}=\frac{997·x_{in}·y_0}{1000·x_0+997·x_{in}}$$
> $y_{out}$即本方法的输出，其中
> $$amountIn=x_{in}$$
> $$reserveIn=x_0$$
> $$reserveOut=y_0$$
> $$amountOut=y_{out}$$
### 3.1.4 getAmountIn
该方法计算当希望获得一定数量（amountOut）的代币B时，应该输入多少数量（amoutnIn）的代币A。getAmountIn是已知$y_{out}$，计算$x_{in}$。根据上述公式可以推导出：
$$x_{in}=\frac{1000·x_0·y_{out}}{997·(y_0-y_{out})}$$
> 最后有一个add(1)，这是为了防止amountIn为小数的情况，加1可以保证输入的数（amountIn）不小于理论的最小值。
### 3.1.5 getAmountsOut
用于计算在使用多个交易对时，输入一定数量（amountIn）的第一种代币，最终能收到多少数量的最后一种代币（amounts）。amounts数组中的第一个元素表示amountIn，最后一个元素表示该目标代币对应的数量。该方法实际上是循环调用getAmountOut方法。
### 3.1.6 getAmountsIn
与getAmountsOut相对，getAmountsIn用于计算当希望收到一定数量（amountOut）的目标代币，应该分别输入多少数量的中间代币。计算方法也是循环调用getAmountIn。

## 3.2 <a href="https://github.com/Uniswap/v2-periphery">UniswapV2Router02</a>
### Router02封装了最常用的几个交易接口；为了满足原生ETH交易需求，大部分接口都支持ETH版本；同时，相比Router01，部分接口增加了FeeOnTrasnferTokens的支持。




