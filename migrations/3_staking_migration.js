const SwanStaking = artifacts.require("SwanStake")
const SwanToken = artifacts.require("Swan");

module.exports = async (deployer,network,accounts) =>{
	deployer.deploy(SwanStaking,SwanToken.address);
};