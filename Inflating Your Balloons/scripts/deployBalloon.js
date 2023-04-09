// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const Balloon = await hre.ethers.getContractFactory("Balloon");
  const balloon = await Balloon.deploy(
    [
      hre.ethers.utils.parseEther("10"),
      hre.ethers.utils.parseEther("10"),
      hre.ethers.utils.parseEther("10")
    ],
    "replace with future air token contract address" // air 
  );

  await balloon.deployed();

  console.log(
    `Balloon Contract deployed to ${balloon.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// https://goerli.etherscan.io/address/0x4ac88E3FA431a6DCbDa6e20c9Be28e40704117f8#code