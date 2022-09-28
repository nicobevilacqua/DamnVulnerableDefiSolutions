[Back](../../README.md)

![](../../cover.png)

**A set of challenges to hack implementations of DeFi in Ethereum.**

Created by [@tinchoabbate](https://twitter.com/tinchoabbate)

---
# Challenge #11 - Backdoor

To incentivize the creation of more secure wallets in their team, someone has deployed a registry of [Gnosis Safe wallets](https://github.com/gnosis/safe-contracts/blob/v1.3.0/contracts/GnosisSafe.sol). When someone in the team deploys and registers a wallet, they will earn 10 DVT tokens.

To make sure everything is safe and sound, the registry tightly integrates with the legitimate [Gnosis Safe Proxy Factory](https://github.com/gnosis/safe-contracts/blob/v1.3.0/contracts/proxies/GnosisSafeProxyFactory.sol), and has some additional safety checks.

Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.

Your goal is to take all funds from the registry. In a single transaction.

- [See contracts](../../contracts/backdoor)
- [Hack it](./backdoor.challenge.js)

## SOLUTION
- [See the explanation here](./SOLUTION.md)
- [See the code here](./backdoor.challenge.solved.js)