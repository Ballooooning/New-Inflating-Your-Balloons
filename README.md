The Ballooooning token has evolved from a standard ERC20 token named Balloon (old contract address:0xf2EcDc4559d62E20b1a7F5FFF5C353f0CD3331C4 https://ftmscan.com/token/0xf2ecdc4559d62e20b1a7f5fff5c353f0cd3331c4) into a combination of an ERC20 token named Air and a Balloon NFT that is automatically sent to the wallet that purchased the Air tokens. However, once you purchase the Air tokens with wFTM, the wFTM is not transferred in one lump sum, instead it is automatically streamed at a rate of 1 Air token per second until it runs out. At any point you can purchase moe Air tokens, or sell them, or even transfer them to someone else. 

When you purchase Air tokens for the first time, you will automatically receive a dyamic NFT of a balloon that will change in colors and grow in size depending on the amount of Air tokens in your wallet. 
For example, There will be 5 "tiers" of your balloon NFT that will increase in size as you stream, or pump, more Air into your balloon NFT according to the illustration below. 

Balance:






# “Waterable” Flower NFTs - Changes Metadata as It Accrues Tokens From a Superfluid Stream

## What is Superfluid

Moving tokens between accounts is usually pretty boring. It's typically done through basic ERC20 transfers. Say I transfer you 100 DAI - this causes my balance to go down by 100 and yours to go up by 100. 

Superfluid's smart contract framework takes this a step forward by introducing a new token standard, called the **Super Token**. 

The Super Token extends the basic ERC20 transfer functionality to include Super Agreements. These Super Agreements give us new and more powerful ways to move tokens on-chain!

The Constant Flow Agreement (CFA) is the most popular Super Agreement and lets us *stream* our Super Tokens. What does streaming even mean?

Streaming refers to the by-the-second movement of tokens between accounts. Imagine Alice is streaming to Bob at a flow rate of 1 DAIx/second. This means that with every passing second, Alice's balance is increasing by 1 DAI and Bob's is decreasing.
<br></br>
<center>
<img src="./resources/img/money-streaming-basic.gif" alt="process" width="40%"/>
</center>
<br></br>

Want to learn more? A more holistic explainer of Superfluid can be found [here](https://docs.superfluid.finance/superfluid/protocol-overview/in-depth-overview).

## Flower NFTs (non-technical overview)

Interacting with the [Flower NFT Contract](./contracts/Flower.sol) is simple - you start by creating a stream of `acceptedToken` to the Flower contract.

The Flower contract reacts and mints a Flower NFT to your address. As your stream goes on, the metadata of the Flower NFT will graduate images as the amount you've streamed so far into the contract increases. You can increase/decrease your flow rate or delete your stream as you please!

Addresses can only have one Flower NFT at once. If you transfer your Flower to another address (that doesn't already have a Flower), you will have your `acceptedToken` stream automatically cancelled if you haven't already done so. The metadata on the NFT will be unchanged (not reset to the first image) after the transfer.

## Try it out live on Goerli Testnet 🎬

1. Clone the repo and build with `npm install`
2. Create a `.env` file and fill out the suggested variables from `.env.template`
   - Make sure the wallet you're providing a private key for has some Goerli ETH in it. This wallet will be receiving the Flower NFT!
3. Mint some WATERx Super Tokens with `npx hardhat run scripts/mintSuperWater.js --network goerli`
4. Stream the WATERx Super Tokens to the Flower contract with `npx hardhat run scripts/streamWater.js --network goerli`
5. Go to [Opensea's Testnet App](https://testnets.opensea.io/) and search your address.
   - You should see an "Evolving Flower NFT". That's it! You are now watering the NFT. Note down its token ID
6. After 5 minutes, go to [this NFT Viewer](https://www.nftviewer.xyz/), click into the "Smart Contract" page. Then, enter the contract address `0xEbEf99eE03571a5957E5d6ee4061940c760b0515` and your token ID.

You'll see the NFT image has changed to show a more grown up flower! If you wait another 5 minutes, you'll see it grows again.

<br></br>
<center>
<img src="./resources/img/flower-growth.png" alt="process" width="40%"/>
</center>
<br></br>