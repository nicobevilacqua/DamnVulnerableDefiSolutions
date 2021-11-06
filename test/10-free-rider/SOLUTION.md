1. Get a flash loan from uniswap
2. Bought all the nfts at 15 ETH
3. Offer all the nfts for 0.000000001 ETH
4. Rebuy the nfts with the new price
5. Send tokens to buyer
6. Claim Reward
7. Repay the flash loan
8. Profit


The bug is located in _buyOne()

```solidity
  // transfer from seller to buyer
  token.safeTransferFrom(token.ownerOf(tokenId), msg.sender, tokenId);

  // pay seller
  payable(token.ownerOf(tokenId)).sendValue(priceToPay);
```

What is happening there is that the ownerOf the token changes after the token.safeTransferFrom() call.

After that the new owner is the contract caller. So, the caller gets the nft and he is pay back with the ether.