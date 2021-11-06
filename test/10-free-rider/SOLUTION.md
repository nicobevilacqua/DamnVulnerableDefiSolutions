[Back](../../README.md)

# Solution challenge #10 - Free rider

First of all, we must know how a flash swap works on Uniswap V2.

- [Flash Swap Documentation](https://docs.uniswap.org/protocol/V2/concepts/core-concepts/flash-swaps)

- [Code example](https://www.youtube.com/watch?v=MxTgk-kvtRM)

Our objective is to buy the NFTs on the marketplace and send them to our buyer. The problem is that we don't have enough money to do it directly (also, the reward would't worth it in that case).

But we were noticed that there is a bug on the contract. So, we must find it and take advantage of it.

Looking at the contract code we found something odd on the **_buyOne** function:

```solidity
  function _buyOne(uint256 tokenId) private {       
      uint256 priceToPay = offers[tokenId];
      require(priceToPay > 0, "Token is not being offered");

      require(msg.value >= priceToPay, "Amount paid is not enough");

      amountOfOffers--;

      // transfer from seller to buyer
      token.safeTransferFrom(token.ownerOf(tokenId), msg.sender, tokenId);

      // pay seller
      payable(token.ownerOf(tokenId)).sendValue(priceToPay);

      emit NFTBought(msg.sender, tokenId, priceToPay);
  }    
```

The bug is located between after **token.safeTransferFrom()**. What the developer is trying to do here is to transfer the NFT ownership to the buyer and send the ether to the seller. But after **token.safeTransferFrom()** is called, **token.ownerOf(tokenId)** will return the buyer address. Thus the ETH is being returned to the buyer and the seller is getting nothing from the transaction.

Thanks to this bug, we will need only 15 ETH to be able to buy all the NFTs.

The strategy that we are going to use is:

1. Get a flash swap from uniswap for 15 ETH
2. Buy all NFTs
3. Transfer the NFTs to the buyer
4. Repay the flash swap (15 ETH + %0.3) to uniswap
5. Profit

All of this must happen in a single transaction. Thus, we will need to create an Attacker contract with the logic.

Also, in consecuence that the marketplace is using safeTransferFrom on the buyOne function, we will need to implemente the function onERC721Received on our attacker contract.

[FreeRiderAttacker.sol](../../contracts/free-rider/FreeRiderAttacker.sol)

```solidity
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract FreeRiderAttacker IERC721Receiver {
```

```solidity
  function onERC721Received(
      address,
      address,
      uint256,
      bytes memory
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
```

[You can find the contract code here](../../contracts/free-rider/FreeRiderAttacker.sol)
