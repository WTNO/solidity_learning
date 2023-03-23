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
> 其中，$x_0$, $y_0$为交换前的两种代币余额，$x_1$, $y_1$为交换后的两种代币余额，$x_{in}$为输入的代币A数量，因为只提供代币A，因此$y_{in}=0$；$y_{out}$为需要计算的代币B数量。<br/>
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
<br/>
## 3.2 <a href="https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol">UniswapV2Router02</a>
### Router02封装了最常用的几个交易接口；为了满足原生ETH交易需求，大部分接口都支持ETH版本；同时，相比Router01，部分接口增加了FeeOnTrasnferTokens的支持。
### ERC20-ERC20
### 3.2.1 addLiquidity 
```java
function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
    // 帮助计算最佳汇率
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
    TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = IUniswapV2Pair(pair).mint(to);
}
```
用户提交交易后，该交易被矿工打包的时间是不确定的，因此提交时的代币价格与交易打包时的价格可能不同，通过amountMin可以控制价格的浮动范围，防止被矿工或机器人套利；同样，deadline可以确保该交易在超过指定时间后将失效。
参数说明：
* address tokenA：代币A
* address tokenB：代币B
* uint amountADesired：希望存入的代币A数量
* uint amountBDesired：希望存入的代币B数量
* uint amountAMin：最少存入的代币A数量
* uint amountBMin：最少存入的代币B数量
* address to：流动性代币接收地址
* uint deadline：请求失效时间
```java
// **** ADD LIQUIDITY ****
function _addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
) internal virtual returns (uint amountA, uint amountB) {
    // 如果是首次添加流动性，则会先创建交易对合约
    if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
        IUniswapV2Factory(factory).createPair(tokenA, tokenB);
    }
    // 获取当前两种代币的数量
    (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
    // 如果都为0，将希望存入的数量赋值
    if (reserveA == 0 && reserveB == 0) {
        (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
        // 计算应该注入的最佳代币数量
        // 计算代币B最优数量：将数量为amountADesired的代币A，按照合约中两种代币余额比例，换算成另一个代币B
        uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        // 如果B最优数量小于等于B期望数量，取A期望数量和B最优数量
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            // 如果B最优数量大于B期望数量，则计算A期望数量，取A最优数量和B期望数量
            uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }
}
```
最后调用UniswapV2Pair合约mint方法铸造流动性代币。

### 3.2.2 removeLiquidity
移除流动性，首先将流动性代币发送到pair合约，根据收到的流动性代币占全部代币比例，计算该流动性代表的两种代币数量。pair合约销毁流动性代币后，用户将收到来自pair合约对应比例的代币。如果低于用户设定的最低预期（amountAMin/amountBMin），则回滚交易。
>理解：将msg.sender也就是用户在这个代币对UniswapV2Pair合约当中的指定数量流动性代币销毁，换成对应数量的tokenA和tokenB提取出来，换成两种代币的原因是为了符合k常值函数约束。<br/>
>注：阅读代码可知pair合约中其本身持有的流动性代币为0，只有在burn前会收到来自用户的流动性代币，然后调用burn时会将pair合约自身持有的所有流动性代币销毁并兑换成相应比例的两种代币给用户

### 3.2.3 removeLiquidityWithPermit 
使用签名移除流动性,用户正常移除流动性时，需要两个操作：
* approve：授权Router合约花费自己的流动性代币（没看到在哪）
* removeLiquidity：调用Router合约移除流动性

除非第一次授权了最大限额的代币，否则每次移除流动性都需要两次交互，这意味着用户需要支付两次手续费。而使用removeLiquidityWithPermit方法，用户可以通过签名方式授权Router合约花费自己的代币，无需单独调用approve，只需要调用一次移除流动性方法即可完成操作，节省了gas费用。同时，由于离线签名不需要花费gas，因此可以每次签名仅授权一定额度的代币，提高安全性。


### 3.2.4 swapExactTokensForTokens
交易时的两个常见场景：
1. 使用指定数量的代币A（输入），尽可能兑换最多数量的代币B（输出）
2. 获得指定数量的代币B（输出），尽可能使用最少数量的代币A（输入）

本方法实现第一个场景，即根据指定的输入代币，获得最多的输出代币。
首先使用Library合约中的getAmountsOut方法，根据兑换路径计算每一次交易的输出代币数量，确认最后一次交易得到的数量（amounts[amounts.length - 1]）不小于预期最少输出（amountOutMin）；将代币发送到第一个交易对地址，开始执行整个兑换交易。
> 假设用户希望使用WETH兑换DYDX，<font color="red">链下计算</font>的最佳兑换路径为WETH → USDC → DYDX，则amountIn为WETH数量，amountOutMin为希望获得最少DYDX数量，path为[WETH address, USDC address, DYDX address]，amounts为[amountIn, USDC amount, DYDX amount]。在_swap执行交易的过程中，每次中间交易获得的中间代币将被发送到下一个交易对地址，以此类推，直到最后一个交易完成，_to地址将收到最后一次交易的输出代币。

### 3.2.5 swapTokensForExactTokens
根据指定的输出代币，使用最少的输入代币完成兑换。

与上面类似，这里先使用Library的getAmountsIn方法反向计算每一次兑换所需的最少输入代币数量，确认计算得出的（扣除手续费后）第一个代币所需的最少代币数不大于用户愿意提供的最大代币数（amountInMax）；将代币发送到第一个交易对地址，调用_swap开始执行整个兑换交易。

### ERC20-ETH
由于core合约只支持ERC20代币交易，为了支持ETH交易，periphery合约需要将ETH与WETH做转换；并为大部分方法提供了ETH版本。兑换主要涉及两种操作：
* 地址转换：由于ETH没有合约地址，因此需要使用WETH合约的deposit和withdraw方法完成ETH与WETH的兑换
* 代币数量转换：ETH的代币需要通过msg.value获取，可根据该值计算对应的WETH数量，而后使用标准ERC20接口即可
### 3.2.6 FeeOnTransferTokens
由于某些代币会在转账（transfer）过程中收取手续费，转账数量与实际收到的数量有差异，因此无法直接通过计算得出中间兑换过程中所需的代币数量，此时应该通过balanceOf方法（而非transfer方法）判断实际收到的代币数量。Router02新增了对Inclusive Fee On Transfer Tokens的支持
