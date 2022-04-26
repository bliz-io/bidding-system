import { starknet } from "hardhat";
import { expect } from "chai";
import { StarknetContract, Account } from "hardhat/types";
import { uint256 } from "starknet";
import { parseUnits } from "ethers/lib/utils";

describe("Listing", function () {
  this.timeout(300_000);

  let listingContract: StarknetContract;
  let nftContract: StarknetContract;
  let accountA: Account;
  let accountB: Account;

  beforeEach(async () => {
    const listingFactory = await starknet.getContractFactory("Listing");
    listingContract = await listingFactory.deploy({ owner: 321 });
    const nftFactory = await starknet.getContractFactory("NFT");
    accountA = await starknet.deployAccount("Argent");
    accountB = await starknet.deployAccount("Argent");

    nftContract = await nftFactory.deploy({
      name: 1,
      symbol: 2,
      minter: accountA.starknetContract.address,
    });
  });

  xit("can create and fetch listings", async () => {
    const { owner } = await nftContract.call("ownerOf");

    expect(owner).to.eq(BigInt(accountA.starknetContract.address));

    await accountA.invoke(nftContract, "approve", {
      to: listingContract.address,
    });

    await listingContract.invoke("create_listing", {
      listing: {
        id: 1,
        nft_contract_address: nftContract.address,
        nft_id: 1,
        owner: accountA.starknetContract.address,
        end_date: 5,
        type_of_award: 6,
        type_of_bid: 7,
        status: 0,
      },
    });
    const { listing } = await listingContract.call("get_listing", {
      listing_id: 1,
    });

    expect(listing).to.deep.include({
      id: 1n,
      nft_contract_address: BigInt(nftContract.address),
      nft_id: 1n,
      owner: BigInt(accountA.starknetContract.address),
      end_date: 5n,
      type_of_award: 6n,
      type_of_bid: 7n,
      status: 0n,
    });

    const res = await nftContract.call("ownerOf");
    expect(res.owner).to.eq(BigInt(listingContract.address));
  });

  it("can finalize listings", async () => {
    await accountA.invoke(nftContract, "approve", {
      to: listingContract.address,
    });

    await listingContract.invoke("create_listing", {
      listing: {
        id: 1,
        nft_contract_address: nftContract.address,
        nft_id: 1,
        owner: accountA.starknetContract.address,
        end_date: 5,
        type_of_award: 6,
        type_of_bid: 7,
        status: 0,
      },
    });

    await listingContract.invoke("finalize_listing", {
      listing_id: 1,
      winner: accountB.starknetContract.address,
    });

    const { listing } = await listingContract.call("get_listing", {
      listing_id: 1,
    });

    expect(listing).to.deep.include({
      id: 1n,
      nft_contract_address: BigInt(nftContract.address),
      nft_id: 3n,
      owner: BigInt(accountA.starknetContract.address),
      end_date: 5n,
      type_of_award: 6n,
      type_of_bid: 7n,
      status: 1n,
    });

    const { owner } = await nftContract.call("ownerOf");

    expect(owner).to.eq(BigInt(accountB.starknetContract.address));
  });
});
