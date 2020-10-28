const SwanStakingTest = artifacts.require("SwanStakingTest");

contract("SwanStakingTest", function() {
  it("should assert true", async function(done) {
    await SwanStakingTest.deployed();
    assert.isTrue(true);
    done();
  });
});
