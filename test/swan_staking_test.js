const SwanStakingTest = artifacts.require("SwanStake");
const ERC20 = artifacts.require("Swan");

var BN = require("bignumber.js");

const { time } = require("@openzeppelin/test-helpers");

contract("SwanStaking", accounts => {
  let erc20Instance = null;
  let swanInstance = null;

  before(async () => {
    erc20Instance = await ERC20.deployed();
    swanInstance = await SwanStakingTest.deployed();
  });

  it("SwanToken address should be correct", async () => {
    const tokenAddress = await swanInstance.swanTokenAddress();
    assert.equal(tokenAddress, erc20Instance.address, "Addresses are not same");
  });

  it("Total Staked Swan tokens should initially be zero", async () => {
    const totalStaked = await swanInstance.totalStakedTokens();
    assert.equal(totalStaked.toString(), "0", "Total Staked is more than 0");
  });

  it("Transferring Balance to User Accounts and Token Contract", async () => {
    const transferAmount = new BN(30000000000000000000000);
    const approveAmount = new BN(2500000000000000000000);
    const contractAmount = new BN(400000000000000000000000);

    const beforeBalance = await erc20Instance.balanceOf(accounts[1]);

    await erc20Instance.transfer(accounts[1], transferAmount);
    await erc20Instance.transfer(accounts[2], 2000);
    await erc20Instance.transfer(swanInstance.address, contractAmount);

    const contractBalance = await erc20Instance.balanceOf(
      erc20Instance.address
    );

    await erc20Instance.approve(swanInstance.address, approveAmount, {
      from: accounts[1]
    });
    await erc20Instance.approve(swanInstance.address, approveAmount, {
      from: accounts[2]
    });
  });

  /**
   * Requirements for testing stake Function
   * Check the Struct update.
   * Increase in Contract Balance
   * userTotalStake mapping
   * isStaker mapping
   *
   **/
  it("User should be able to STAKE $2k(or more) in Main Account", async () => {
    const stakeAmount = new BN(2000000000000000000000);

    const bool_beforeStake = await swanInstance.isStaker(accounts[1]);

    const tokenBalanceBeforeStake = await swanInstance.userTotalStakes(
      accounts[1]
    );
    const staked = await swanInstance.stake(stakeAmount, { from: accounts[1] });
    const event = staked.logs[0].args;

    const bool_afterStake = await swanInstance.isStaker(accounts[1]);
    const tokenBalanceAfterStake = await swanInstance.userTotalStakes(
      accounts[1]
    );
    const totalStakedTokens = await swanInstance.totalStakedTokens();

    const currentTokenBalance =
      tokenBalanceAfterStake - tokenBalanceBeforeStake;

    assert.equal(event._user, accounts[1], "User address is not Same");
    assert.equal(
      event._amount.toString(),
      "2000000000000000000000",
      "Amount entered is not Same"
    );
    assert.equal(
      event._lockupPeriod.toString(),
      "4",
      "LockUpPeriod is not same"
    );
    assert.equal(
      event._interest.toString(),
      "14",
      "Interest assigned is wrong"
    );

    assert.equal(
      bool_beforeStake,
      false,
      "User assigned as Staker before Staking"
    );
    assert.equal(
      bool_afterStake,
      true,
      "User NOT assigned as Staker even after Staking"
    );
    assert.equal(
      BigInt(currentTokenBalance).toString(),
      event._amount.toString(),
      "User token staking details didn't update as expected"
    );
    assert.equal(
      totalStakedTokens.toString(),
      "402000000000000000000000",
      "Staking Contract token balance did not update as expected"
    );
  });

  /**
   *Requirements for testing investing Functions
   * Must increases Contract's Balance
   * Must modify the struct
   * Must deduct User balance of Tokens
   * Must update userTotalStake mapping
   * APY must be added correctly
   **/

  it("STAKERs should be able to Stake for 1 month LockUp period with High APY", async () => {
    const stake = await swanInstance.earnInterest(1000, 1, {
      from: accounts[1]
    });
    const tokenBalanceAfterStake = await swanInstance.userTotalStakes(
      accounts[1]
    );

    const totalStakedTokens = await swanInstance.totalStakedTokens();

    const event = stake.logs[0].args;

    assert.equal(
      event._proposalId.toString(),
      "1",
      "ProposalId was not assigned correctly"
    );
    assert.equal(event._user, accounts[1], "User address is not Same");
    assert.equal(
      event._amount.toString(),
      "1000",
      "Amount entered is not Same"
    );
    assert.equal(
      event._lockupPeriod.toString(),
      "1",
      "LockUpPeriod is not same"
    );
    assert.equal(
      event._interest.toString(),
      "16",
      "APY not assigned currectly for 16%"
    );
    assert.equal(
      tokenBalanceAfterStake.toString(),
      "2000000000000000001000",
      "User token staking details didn't update as expected"
    );
    assert.equal(
      totalStakedTokens.toString(),
      "402000000000000000001000",
      "Staking Contract token balance did not update as expected"
    );
  });

  it("Non-STAKERs should be able to Stake for 1 month LockUp period with Low APY", async () => {
    const stake = await swanInstance.earnInterest(1000, 1, {
      from: accounts[2]
    });
    const tokenBalanceAfterStake = await swanInstance.userTotalStakes(
      accounts[2]
    );

    const totalStakedTokens = await swanInstance.totalStakedTokens();

    const event = stake.logs[0].args;

    assert.equal(
      event._proposalId.toString(),
      "1",
      "ProposalId was not assigned correctly"
    );
    assert.equal(event._user, accounts[2], "User address is not Same");
    assert.equal(
      event._amount.toString(),
      "1000",
      "Amount entered is not Same"
    );
    assert.equal(
      event._lockupPeriod.toString(),
      "1",
      "LockUpPeriod is not same"
    );
    assert.equal(
      event._interest.toString(),
      "12",
      "APY not assigned currectly for 12%"
    );

    assert.equal(
      tokenBalanceAfterStake.toString(),
      "1000",
      "User token staking details didn't update as expected"
    );
    assert.equal(
      totalStakedTokens.toString(),
      "402000000000000000002000",
      "Staking Contract token balance did not update as expected"
    );
  });

  it("STAKERs should be able to Stake for 3 month LockUp period with High APY", async () => {
    const stake = await swanInstance.earnInterest(1000, 3, {
      from: accounts[1]
    });
    const tokenBalanceAfterStake = await swanInstance.userTotalStakes(
      accounts[1]
    );

    const totalStakedTokens = await swanInstance.totalStakedTokens();
    const event = stake.logs[0].args;

    assert.equal(
      event._proposalId.toString(),
      "2",
      "ProposalId was not assigned correctly"
    );
    assert.equal(event._user, accounts[1], "User address is not Same");
    assert.equal(
      event._amount.toString(),
      "1000",
      "Amount entered is not Same"
    );
    assert.equal(
      event._lockupPeriod.toString(),
      "3",
      "LockUpPeriod is not same"
    );
    assert.equal(
      event._interest.toString(),
      "20",
      "APY not assigned currectly for 16%"
    );

    assert.equal(
      tokenBalanceAfterStake.toString(),
      "2000000000000000002000",
      "User token staking details didn't update as expected"
    );
    assert.equal(
      totalStakedTokens.toString(),
      "402000000000000000003000",
      "Staking Contract token balance did not update as expected"
    );
  });

  it("Non-STAKERs should be able to Stake for 3 month LockUp period with Low APY", async () => {
    const stake = await swanInstance.earnInterest(1000, 3, {
      from: accounts[2]
    });
    const tokenBalanceAfterStake = await swanInstance.userTotalStakes(
      accounts[2]
    );

    const totalStakedTokens = await swanInstance.totalStakedTokens();

    const event = stake.logs[0].args;
    assert.equal(
      event._proposalId.toString(),
      "2",
      "ProposalId was not assigned correctly"
    );
    assert.equal(event._user, accounts[2], "User address is not Same");
    assert.equal(
      event._amount.toString(),
      "1000",
      "Amount entered is not Same"
    );
    assert.equal(
      event._lockupPeriod.toString(),
      "3",
      "LockUpPeriod is not same"
    );
    assert.equal(
      event._interest.toString(),
      "16",
      "APY not assigned currectly for 12%"
    );

    assert.equal(
      tokenBalanceAfterStake.toString(),
      "2000",
      "User token staking details didn't update as expected"
    );
    assert.equal(
      totalStakedTokens.toString(),
      "402000000000000000004000",
      "Staking Contract token balance did not update as expected"
    );
  });

  // Increasing time to 1 second more than 6 hours
  it("Time should increase", async () => {
    await time.increase(time.duration.seconds(21601));
    const interest = await swanInstance.totalPoolRewards(accounts[1], 1);
  });

  it("Staker should get weekly claims for 1 month investments", async () => {
    await swanInstance.payOuts(1, { from: accounts[1] });
    const interest = await swanInstance.totalPoolRewards(accounts[1], 1);

    assert.equal(
      interest.toString(),
      "40",
      "Interest was not assigned correctly"
    );
  });

  it("Non-STAKERs should get weekly claims for 1 month investments", async () => {
    await swanInstance.payOuts(1, { from: accounts[2] });
    const interest = await swanInstance.totalPoolRewards(accounts[2], 1);

    assert.equal(
      interest.toString(),
      "30",
      "Interest was not assigned correctly"
    );
  });

  it("Staker should get weekly claims for 3 month investments", async () => {
    await swanInstance.payOuts(2, { from: accounts[1] });
    const interest = await swanInstance.totalPoolRewards(accounts[1], 2);

    assert.equal(
      interest.toString(),
      "16",
      "Interest was not assigned correctly"
    );
  });

  it("Non-STAKERs should get weekly claims for 3 month investments", async () => {
    await swanInstance.payOuts(2, { from: accounts[2] });
    const interest = await swanInstance.totalPoolRewards(accounts[2], 2);
    assert.equal(
      interest.toString(),
      "13",
      "Interest was not assigned correctly"
    );
  });

  // // 	/**
  // // 		*Requirements for testing Withdrawl Functions
  // // 		* Must transfer invested amount
  // // 		* Must transfer Interest Earned
  // // 		* Must update the totalPoolRewards
  // // 		* Must deduct user's total stakes in contract
  // // 	**/

  // Time increased to 1 month
  it("Time should increase", async () => {
    await time.increase(time.duration.seconds(2629749));
    const interest = await swanInstance.totalPoolRewards(accounts[1], 1);
  });

  it("Stakers should be able to withdraw invested amounts after 1 month period", async () => {
    const claimedInterest = await swanInstance.claimInterestTokens(1, {
      from: accounts[1]
    });

    const userBalance = await erc20Instance.balanceOf(accounts[1]);
    const userBalanceInContract = await swanInstance.userTotalStakes(
      accounts[1]
    );
    const boolWithdrawn = await swanInstance.interestAccountDetails(
      accounts[1],
      1
    );
    const interest = await swanInstance.totalPoolRewards(accounts[1], 1);

    const event = claimedInterest.logs[0].args;

    assert.equal(
      event._amount.toString(),
      "1120",
      "Token sent to user is not right"
    );
    assert.equal(
      interest.toString(),
      "40",
      "Interest was not assigned correctly"
    );
    assert.equal(boolWithdrawn[6], true, "User withdraw sign is still FALSE");
    assert.equal(
      userBalance.toString(),
      "27999999999999999999176",
      "Balance of user didn't increase"
    );
    assert.equal(
      userBalanceInContract.toString(),
      "2000000000000000001000",
      "User Balance didn't decrease in Contract"
    );
  });
  it("Non-STAKERs should be able to withdraw invested amounts after 1 month period", async () => {
    const claimedInterest = await swanInstance.claimInterestTokens(1, {
      from: accounts[2]
    });

    const userBalance = await erc20Instance.balanceOf(accounts[2]);
    const userBalanceInContract = await swanInstance.userTotalStakes(
      accounts[2]
    );
    const boolWithdrawn = await swanInstance.interestAccountDetails(
      accounts[2],
      1
    );
    const interest = await swanInstance.totalPoolRewards(accounts[2], 1);

    const event = claimedInterest.logs[0].args;

    assert.equal(
      event._amount.toString(),
      "1090",
      "Token sent to user is not right"
    );
    assert.equal(
      interest.toString(),
      "30",
      "Interest was not assigned correctly"
    );
    assert.equal(boolWithdrawn[6], true, "User withdraw sign is still FALSE");
    assert.equal(
      userBalance.toString(),
      "1133",
      "Balance of user didn't increase"
    );
    assert.equal(
      userBalanceInContract.toString(),
      "1000",
      "User Balance didn't decrease in Contract"
    );
  });

  // Time increased to 4 month
  it("Time should increase", async () => {
    await time.increase(time.duration.seconds(10518988));
    const interest = await swanInstance.totalPoolRewards(accounts[1], 1);
  });

  it("Stakers should be able to withdraw invested amounts after 3 month period", async () => {
    const claimedInterest = await swanInstance.claimInterestTokens(2, {
      from: accounts[1]
    });

    const userBalance = await erc20Instance.balanceOf(accounts[1]);
    const userBalanceInContract = await swanInstance.userTotalStakes(
      accounts[1]
    );
    const boolWithdrawn = await swanInstance.interestAccountDetails(
      accounts[1],
      2
    );
    const interest = await swanInstance.totalPoolRewards(accounts[1], 2);

    const event = claimedInterest.logs[0].args;

    assert.equal(
      event._amount.toString(),
      "1184",
      "Token sent to user is not right"
    );
    assert.equal(
      interest.toString(),
      "16",
      "Interest was not assigned correctly"
    );
    assert.equal(boolWithdrawn[6], true, "User withdraw sign is still FALSE");
    assert.equal(
      userBalance.toString(),
      "28000000000000000000360",
      "Balance of user didn't increase"
    );
    assert.equal(
      userBalanceInContract.toString(),
      "2000000000000000000000",
      "User Balance didn't decrease in Contract"
    );
  });

  it("Non-STAKERs should be able to withdraw invested amounts after 3 month period", async () => {
    const claimedInterest = await swanInstance.claimInterestTokens(2, {
      from: accounts[2]
    });

    const userBalance = await erc20Instance.balanceOf(accounts[2]);
    const userBalanceInContract = await swanInstance.userTotalStakes(
      accounts[2]
    );
    const boolWithdrawn = await swanInstance.interestAccountDetails(
      accounts[2],
      2
    );
    const interest = await swanInstance.totalPoolRewards(accounts[2], 2);

    const event = claimedInterest.logs[0].args;

    assert.equal(
      event._amount.toString(),
      "1147",
      "Token sent to user is not right"
    );
    assert.equal(
      interest.toString(),
      "13",
      "Interest was not assigned correctly"
    );
    assert.equal(boolWithdrawn[6], true, "User withdraw sign is still FALSE");
    assert.equal(
      userBalance.toString(),
      "2280",
      "Balance of user didn't increase"
    );
    assert.equal(
      userBalanceInContract.toString(),
      "0",
      "User Balance didn't decrease in Contract"
    );
  });

  it("Stakers should be able to CLAIM their Staked Tokens with INTEREST", async () => {
    await swanInstance.claimStakeTokens({ from: accounts[1] });

    const userBalance = await erc20Instance.balanceOf(accounts[1]);
    const isStaker = await swanInstance.isStaker(accounts[1]);

    assert.equal(isStaker, false, "User wasn't marked as Non Staker");
    assert.equal(
      userBalance.toString(),
      "30280000000000000000360",
      "User's Balance Didn't increase"
    );
  });
});
