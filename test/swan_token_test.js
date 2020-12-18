const ERC20 = artifacts.require("Swan");
const SwanStakingContract = artifacts.require("SwanStake");

const { time } = require("@openzeppelin/test-helpers");

contract("Swan ERC20 Token", accounts => {
  let erc20Instance = null;

  before(async () => {
    erc20Instance = await ERC20.deployed();
  });

  //Testing the SWAN Token Contract
  it("Owner is Correct", async () => {
    const owner = await erc20Instance.owner();
    assert.equal(owner, accounts[0], "Owner's address is wrongly assigned");
  });

  it("Name of the token should be SWAN FINANCE", async () => {
    const name = await erc20Instance.name();
    assert.equal(name, "Swan Finance", "Name is wrongly assigned");
  });

  it("Symbol should be Swan", async () => {
    const symbol = await erc20Instance.symbol();
    assert.equal(symbol, "SWAN", "Token symbol is not correct");
  });

  it("Total Supply Should be 50000000000000000000000000000", async () => {
    const totalSupply = await erc20Instance.totalSupply();
    assert.equal(
      totalSupply.toString(),
      "50000000000000000000000000000",
      "Total Supply is wrongly assigned"
    );
  });

  it("Minted tokens should be assigned to Owner", async () => {
    const totalTokens = await erc20Instance.balanceOf(accounts[0]);
    assert.equal(
      totalTokens.toString(),
      "50000000000000000000000000000",
      "Tokens Minted doesn't match tokens owned by Contract"
    );
  });

  it("Owner should be able to transfer Swan Tokens", async () =>{
    const balanceBefore = await erc20Instance.balanceOf(accounts[1]);
    await erc20Instance.transfer(accounts[1],100000);
    const balanceAfter = await erc20Instance.balanceOf(accounts[1]);

    assert.equal(balanceBefore.toString(),"0","Balance is Not Zero");
    assert.equal(balanceAfter.toString(),"100000","Balance didn't update");

  })


  it("User should be able to transfer Swan Tokens", async () =>{
    const balanceBefore = await erc20Instance.balanceOf(accounts[2]);
    await erc20Instance.transfer(accounts[2],1000,{from:accounts[1]});
    const balanceAfter = await erc20Instance.balanceOf(accounts[2]);
    const balanceofSender = await erc20Instance.balanceOf(accounts[1])

    assert.equal(balanceBefore.toString(),"0","Balance is Not Zero");
    assert.equal(balanceAfter.toString(),"1000","Balance didn't update");
    assert.equal(balanceofSender.toString(),"99000","Balance didn't update from sender")

  })
 
  // it("Should be able to PAUSE Token and check for Correctness", async () => {
  //   await erc20Instance.pause({ from: accounts[0] });

  //   try {
  //     await erc20Instance.transfer(accounts[5], 1000);
  //   } catch (error) {
  //     const invalidOpcode = error.message.search("revert") >= 0;
  //     assert(invalidOpcode, "Expected revert, got '" + error + "' instead");
  //   }

  //   await erc20Instance.unpause({ from: accounts[0] });
  //   await erc20Instance.transfer(accounts[5], 1000);

  //   const balanceOfUser = await erc20Instance.balanceOf(accounts[2]);

  //   assert.equal(
  //     balanceOfUser.toString(),
  //     "1000",
  //     "Recipient balance is not correct"
  //   );
  // });
});
