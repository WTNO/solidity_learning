## <a href="https://github.com/starcoinorg/starcoin">Starcoin DAO</a>（使用Move语言）
<a href="https://starcoin.medium.com/a-guide-to-starcoin-dao-exploring-dao-functionality-of-on-chain-governance-4844da24c50a">简易说明</a>
### Starcoin 的 DAO 实现和 Ethereum 的 DAO 实现之间的一个显着差异是，在 Starcoin 中，每种类型的提案都由一个单独的合约模块控制，该模块实现了提案的发起和执行。
1. 在 Starcoin 中，每种类型的提案都由一个单独的合约模块控制，该模块实现了提案的发起和执行。这是因为在以太坊中，智能合约可以通过动态分发的方式调用其他合约接口，所以单个合约只需要在合约内部动态调用就可以发起所有类型的提案。但是Move是函数调用静态分布的模型；所有代码调用必须在编译时确定，不能做动态分配。因此出现了上面提到的区别。DAO 模块抽象出提议并用 proposal_id 标识一个提议。不过，它并不关心提案，而是让用户自己决定。投票时，用户通过 DAPP 获取提案的详细信息，然后直接调用 DAO 模块的接口，对提案投赞成票或反对票。这样，不同的提案可以实现它们的提案逻辑，但共享 DAO 模块的投票功能。
2. 用户投票时，需要质押自己的Token，票数与Token数量成正比，即一币一票。在投票期间，用户可以多次投票、撤票，甚至互相反对（从赞成到反对，从反对到赞成）。投票期结束后，用户可以立即撤回质押的代币。
3. 投票期结束后，如果投票通过且赞成票数超过反对票数，则该提案通过。此时，任何人都可以发送交易将提案标记为待处理，并将其放入待执行队列中。执行期结束后，任何人都可以发送交易来执行提案。提案执行后，提案发起者可以删除自己的提案，释放提案占用的链上空间。