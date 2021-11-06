[Back](../../README.md)

![](../../cover.png)

**A set of challenges to hack implementations of DeFi in Ethereum.**

Created by [@tinchoabbate](https://twitter.com/tinchoabbate)

---
# Challenge #12 - Climber

There's a secure vault contract guarding 10 million DVT tokens. The vault is upgradeable, following the UUPS pattern.

The owner of the vault, currently a timelock contract, can withdraw a very limited amount of tokens every 15 days.

On the vault there's an additional role with powers to sweep all tokens in case of an emergency.

On the timelock, only an account with a "Proposer" role can schedule actions that can be executed 1 hour later.

Your goal is to empty the vault.

- [See contracts](../../contracts/climber)
- [Hack it](./climber.challenge.js)

## SOLUTION
- [See the explanation here](./SOLUTION.md)
- [See the code here](./climber.challenge.solved.js)