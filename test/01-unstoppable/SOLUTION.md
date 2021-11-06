## Solution

If we analize the UnstoppableLender.sol contract we would see that there is a property called poolBalance that is being updated every time an user deposits tokens on the contract.

```solidity
contract UnstoppableLender is ReentrancyGuard {

    IERC20 public immutable damnValuableToken;
    uint256 public poolBalance;
```

Then, in the flashLoan function, we can see that there is an extra validation before the transfer is being triggered where the contract compares the value on **poolBalance** with the actual token balance for the contract addres.

```solidity
  // Ensured by the protocol via the `depositTokens` function
  assert(poolBalance == balanceBefore);
```

The issue here is that the contract updates the value of **poolBalance** only when an user deposits tokens through **depositTokens**. But that is not the only way that an user could transfer tokens to the contract address. 

An attacker could easily call the IRC20.transfer function and transfer a small amount of tokens to the contract address causing a mistmach on the **poolBalance** and, thus, blocking the assertion on **flashLoan** disabling the contract completely.

And that is what we're doing here to solve the puzzle.

```js
  it('Exploit', async function () {
    this.token.transfer(this.pool.address, 1);
  });
```