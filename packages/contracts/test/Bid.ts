import { starknet, ethers } from "hardhat";
import { expect } from "chai";
import { StarknetContract, Account } from "hardhat/types";

import { computeHashOnElements } from "starknet/utils/hash";

describe("Bid", function () {
  this.timeout(300_000);

  let contract: StarknetContract;
  let accountA : Account;
  let accountB : Account;

  beforeEach(async () => {
    console.log("Start deploying contract...");
    const counterFactory = await starknet.getContractFactory("Bid");
    contract = await counterFactory.deploy();
    console.log("...End");
    console.log("Deploying account A...");
    accountA = await starknet.deployAccount("OpenZeppelin");
    console.log("...End");
    console.log("Deploying account B...");
    accountB = await starknet.deployAccount("OpenZeppelin");
    console.log("...End");
  });

  it.only("can bid onto something", async () => {
    const bid = [
      accountA.starknetContract.address,
      1,
      1,
      1,
    ];
    console.log(bid);

    const hash = computeHashOnElements(bid);
    console.log(hash);

    const place_bid_args = {
      bid_hash: hash,
    } 
    
    const tx = await accountA.invoke(contract, "place_bid", place_bid_args);
    console.log(tx);

    const confirm_bid_args = {
      bid_id: tx,
      auction_id: 1,
      proof: 1,
    }
    const tx2 = await accountA.invoke(contract, "confirm_bid", confirm_bid_args);
  });

});
