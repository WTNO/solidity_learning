本指南将介绍OpenZeppelin的Governor合约的工作原理，如何设置以及如何使用它来创建提案、投票并执行它们，使用Ethers.js和Tally提供的工具。


## 介绍
分布式协议在公开发布后不断发展。通常，最初的团队在最初的阶段保留对这种发展的控制权，但最终将其委托给利益相关者社区。这个社区做出决策的过程被称为链上治理，它已成为分散式协议的核心组成部分，推动各种决策，如参数调整、智能合约升级、与其他协议的集成、财务管理、赠款等。

这个治理协议通常在一个特殊用途的合约中实现，称为“Governor”。Compound设计的GovernorAlpha和GovernorBravo合约迄今为止非常成功和受欢迎，但缺点是具有不同要求的项目必须分叉代码以根据其需要进行定制，这可能带来引入安全问题的高风险。对于OpenZeppelin Contracts，我们着手构建一套Governor合约的模块化系统，以避免分叉，并使用Solidity继承编写小模块来满足不同的要求。您将在OpenZeppelin Contracts中找到最常见的需求，但编写其他需求很简单，我们将在未来的发布中根据社区的要求添加新功能。此外，OpenZeppelin Governor的设计需要最少的存储使用，并产生更高效的操作。

## 兼容性
OpenZeppelin的Governor系统设计时考虑了与基于Compound的GovernorAlpha和GovernorBravo的现有系统的兼容性。因此，您会发现许多模块都有两个变体，其中一个是为与这些系统兼容而构建的。

## ERC20Votes和ERC20VotesComp
ERC20扩展以跟踪投票和投票委托就是其中之一。较短的版本是更通用的版本，因为它可以支持大于2 ^ 96的代币供应量，而“Comp”变体在这方面有限制，但恰好适合GovernorAlpha和Bravo使用的COMP代币的接口。这两个合约变体共享相同的事件，因此仅查看事件时它们是完全兼容的。

## Governor和GovernorCompatibilityBravo
OpenZeppelin的Governor合约默认情况下与Compound的GovernorAlpha或Bravo不兼容。即使事件是完全兼容的，提案生命周期函数（创建、执行等）也具有不同的签名，旨在优化存储使用。GovernorAlpha和Bravo的其他函数同样不可用。可以通过继承GovernorCompatibilityBravo模块来选择更高级别的兼容性，该模块包含例如提出和执行等提案生命周期函数。

请注意，即使使用此模块，`proposalId`的计算方式仍将有所不同。Governor使用提案参数的哈希值，目的是通过事件索引将其数据保持在链下，而原始的Bravo实现使用顺序的`proposalId`。由于这个和其他差异，一些来自GovernorBravo的函数不包含在兼容性模块中。

## GovernorTimelockControl和GovernorTimelockCompound
在使用Governor合约的计时锁时，可以使用OpenZeppelin的TimelockController或Compound的Timelock。根据计时锁的选择，应选择相应的Governor模块：GovernorTimelockControl或GovernorTimelockCompound。这使您可以将现有的GovernorAlpha实例迁移到基于OpenZeppelin的Governor，而无需更改正在使用的计时锁。

## Tally
Tally是一个完整的用户拥有的链上治理应用程序。它包括投票仪表板、提案创建向导、实时研究和分析以及教育内容。

对于所有这些选项，Governor将与Tally兼容：用户将能够创建提案、可视化投票权和支持者、浏览提案并投票。特别是对于提案创建，项目还可以使用Defender Admin作为替代界面。

在本指南的其余部分，我们将重点介绍原始的OpenZeppelin Governor功能的新部署，不关心与GovernorAlpha或Bravo的兼容性。

## 代币
我们治理机制中每个账户的投票权将由一个ERC20代币确定。该代币必须实现ERC20Votes扩展。该扩展将跟踪历史余额，以便从过去的快照中检索投票权，而不是当前余额，这是一个重要的保护措施，可以防止双重投票。

```java
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract MyToken is ERC20, ERC20Permit, ERC20Votes {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
```

如果你的项目已经有了一种实时代币，但不包括ERC20Votes且不可升级，你可以使用ERC20Wrapper将其封装成治理代币。这将允许代币持有人通过1对1封装他们的代币来参与治理。

```java
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";

contract MyToken is ERC20, ERC20Permit, ERC20Votes, ERC20Wrapper {
    constructor(IERC20 wrappedToken)
        ERC20("MyToken", "MTK")
        ERC20Permit("MyToken")
        ERC20Wrapper(wrappedToken)
    {}

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
```

>目前在OpenZeppelin Contracts中唯一可用的投票权来源是ERC721Votes。没有提供此功能的ERC721代币可以使用ERC721Votes和ERC721Wrapper的组合包装成投票代币。

>代币用于存储投票余额的内部时钟将决定附加到其上的Governor合约的操作模式。默认情况下，使用区块编号。自v4.9以来，开发人员可以覆盖IERC6372时钟，使用时间戳代替区块编号。

## Governor
初步，我们将建立一个没有时间锁的Governor。核心逻辑由Governor合约提供，但我们仍需要选择：1）如何确定投票权，2）需要多少票才能达成法定人数，3）人们在投票时有哪些选项以及如何计算这些选票，4）应使用哪种代币进行投票。每个方面都可以通过编写自己的模块来进行自定义，或者更容易地从OpenZeppelin Contracts中选择一个模块。

对于1），我们将使用GovernorVotes模块，它钩入IVotes实例，根据投票提案激活时持有的代币余额来确定帐户的投票权。这个模块需要代币的地址作为构造函数参数。这个模块还会发现代币使用的时钟模式（ERC6372）并将其应用于Governor。

对于2），我们将使用GovernorVotesQuorumFraction，它与ERC20Votes一起工作，将法定人数定义为提案投票权在检索时总供应量的百分比。这需要一个构造函数参数来设置百分比。现在大多数Governors使用4％，因此我们将用参数4来初始化模块（这表示百分比，结果为4％）。

对于3），我们将使用GovernorCountingSimple，这是一个模块，为投票者提供了3个选项：支持、反对和弃权，只有支持和弃权投票将被计入法定人数。

除了这些模块外，Governor本身还有一些参数必须设置。

votingDelay：在提案创建后多长时间应固定投票权。较长的投票延迟为用户提供了必要的时间来取消质押代币。

votingPeriod：提案保持开放投票的时间有多长。

这些参数在代币时钟定义的单位中指定。假设代币使用块编号，并假设块时间约为12秒，则我们将设置votingDelay = 1天= 7200个块，votingPeriod = 1周= 50400个块。

我们还可以选择设置提案阈值。这将限制提案创建仅限于拥有足够投票权的帐户。

```java
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

contract MyGovernor is Governor, GovernorCompatibilityBravo, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    constructor(IVotes _token, TimelockController _timelock)
        Governor("MyGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 7200; // 1 day
    }

    function votingPeriod() public pure override returns (uint256) {
        return 50400; // 1 week
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0;
    }

    // The functions below are overrides required by Solidity.

    function state(uint256 proposalId)
        public
        view
        override(Governor, IGovernor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override(Governor, GovernorCompatibilityBravo, IGovernor)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, IERC165, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

## 时间锁
在治理决策中添加时间锁是一个好的做法。这样做可以让用户在执行决策之前退出系统，如果他们不同意该决策。我们将使用OpenZeppelin的TimelockController结合GovernorTimelockControl模块。

><font color="yellow">IMPORTANT</font>  
>当使用时间锁时，时间锁将执行提案，因此时间锁应该持有任何资金、所有权和访问控制角色。在4.5版本之前，使用时间锁时在治理合约中无法恢复资金！在4.3版本之前，使用Compound时间锁时，时间锁中的以太币不容易被访问。

TimelockController使用了AccessControl设置，我们需要了解它以设置角色。
* Proposer角色负责排队操作：这是Governor实例应该授予的角色，它可能是系统中唯一的提案者。
* Executor角色负责执行已经可用的操作：我们可以将此角色分配给特殊的零地址，以允许任何人执行（如果操作特别时间敏感，则应将Governor作为执行者）。
* 最后，有一个Admin角色，可以授予和撤销前两个角色：这是一个非常敏感的角色，将自动授予时间锁本身，并可选择授予第二个帐户，用于方便设置，但应立即放弃该角色。

## 提案生命周期
让我们走过如何在我们新部署的Governor上创建和执行提案的过程。

提案是Governor合约将执行的一系列操作，如果它通过了。每个操作由目标地址、calldata编码的函数调用和要包含的ETH数量组成。此外，提案包括一个易于理解的描述。

## 创建提案
假设我们想创建一个提案，向一个团队提供一个补助，以治理宝库中的ERC20代币形式。这个提案将包含一个单一的操作，其中目标是ERC20代币，calldata是编码的函数调用transfer(<team wallet>, <grant amount>)，附加0 ETH。

通常情况下，提案将使用Tally或Defender等接口的帮助创建。在这里，我们将展示如何使用Ethers.js创建提案。

首先，我们获取所有必要的提案操作参数。

```java
const tokenAddress = ...;
const token = await ethers.getContractAt(‘ERC20’, tokenAddress);

const teamAddress = ...;
const grantAmount = ...;
const transferCalldata = token.interface.encodeFunctionData(‘transfer’, [teamAddress, grantAmount]);
```

现在，我们已经准备好调用Governor的propose函数。请注意，我们不传递一个操作数组，而是传递三个数组，分别对应于目标列表、值列表和calldata列表。在这种情况下，它只有一个操作，所以很简单：

```java
await governor.propose(
  [tokenAddress],
  [0],
  [transferCalldata],
  “Proposal #1: Give grant to team”,
);
```
这将创建一个新的提案，提案ID是通过将提案数据哈希在一起获得的，也可以在交易日志的事件中找到。

## 投票
一旦提案激活，代表们就可以投票。请注意，投票权力由代表持有：如果代币持有人想参与，他们可以将信任的代表设置为他们的代表，或者通过自我委托他们的投票权力来成为代表。

投票通过与Governor合约交互，通过castVote系列函数进行。投票者通常会从像Tally这样的治理UI中调用此函数。

## 执行提案
一旦投票期结束，如果达到法定人数（足够的投票权参与）并且大多数投票赞成，提案将被视为成功，并可以继续执行。一旦提案通过，它可以从您投票的同一位置排队并执行。


现在，我们将看到如何使用Ethers.js手动执行此操作。

如果设置了时间锁，执行的第一步是排队。您会注意到，无论是queue函数还是execute函数都需要传递整个提案参数，而不仅仅是提案ID。这是必要的，因为这些数据不存储在链上，以节省燃气。请注意，这些参数始终可以在合约发出的事件中找到。唯一没有完全发送的参数是描述，因为只需要以其哈希形式计算提案ID。

要排队，我们调用queue函数：
```java
const descriptionHash = ethers.utils.id(“Proposal #1: Give grant to team”);

await governor.queue(
  [tokenAddress],
  [0],
  [transferCalldata],
  descriptionHash,
);
```

这将导致州长与时间锁合约互动，并在必需的延迟后排队执行操作。足够的时间过去后（根据时间锁参数），提案可以被执行。如果一开始没有时间锁，那么在提案成功后可以立即运行此步骤。

```java
await governor.execute(
  [tokenAddress],
  [0],
  [transferCalldata],
  descriptionHash,
);
```

执行提案将把 ERC20 代币转移给所选择的接收者。总结一下：我们建立了一个系统，其中一个项目的代币持有者的集体决策控制着财政库，并且所有行动都通过由链上投票强制执行的提案来执行。
# 基于时间戳的治理
## 动机
由于块之间的时间不一致或不可预测，因此有时难以处理以块数表示的持续时间。这在一些 L2 网络中尤为明显，因为块的生成基于区块链使用情况。使用块数也可能导致治理规则受到修改预期块间时间的网络升级的影响。

将块号替换为时间戳的困难在于，当查询过去的投票时，州长和代币必须同时使用相同的格式。如果代币围绕块号设计，则州长无法可靠地执行基于时间戳的查找。

因此，设计基于时间戳的投票系统始于代币。

## 代币
自 v4.9 起，所有投票合约（包括 ERC20Votes 和 ERC721Votes）都依赖于 IERC6372 用于时钟管理。为了从使用块号转换为使用时间戳，只需要重写 clock() 和 CLOCK_MODE() 函数即可。
```java
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "github.com/openzeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "github.com/openzeppelin/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "github.com/openzeppelin/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract MyToken is ERC20, ERC20Permit, ERC20Votes {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}

    // Overrides IERC6372 functions to make the token & governor timestamp-based

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
```

## Governor

Governor将自动检测代币使用的时钟模式并进行适应。在Governor合约中不需要覆盖任何内容。但是，时钟模式确实会影响某些值的解释。因此，需要相应地设置 votingDelay() 和 votingPeriod()。

```java
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

contract MyGovernor is Governor, GovernorCompatibilityBravo, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    constructor(IVotes _token, TimelockController _timelock)
        Governor("MyGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    function votingDelay() public pure virtual override returns (uint256) {
        return 1 days;
    }

    function votingPeriod() public pure virtual override returns (uint256) {
        return 1 weeks;
    }

    function proposalThreshold() public pure virtual override returns (uint256) {
        return 0;
    }

    // ...
}
```

## 免责声明

基于时间戳的投票是最近在 EIP-6372 和 EIP-5805 中正式确定并在 v4.9 中引入的功能。在此功能发布时，像 Tally 这样的治理工具尚不支持它。虽然时间戳的支持应该很快就会到来，但用户可能会遇到截止日期和持续时间的无效报告。这些离线工具的无效报告不会影响治理合约的链上安全性和功能。

支持时间戳的Governor（v4.9 及以上版本）与旧代币（v4.9 之前的版本）兼容，并将以“块号”模式（所有旧代币均采用该模式）运行。另一方面，旧的Governor实例（v4.9 之前）与使用时间戳的新代币不兼容。如果您更新代币代码以使用时间戳，请确保同时更新您的Governor代码。


