const HDWalletProvider = require("@truffle/hdwallet-provider");
require('dotenv').config();
console.log(process.env.MNEMONIC, process.env.INFURA_API_KEY, process.env.ETHERSCAN_API_KEY)

module.exports = {
  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  contracts_directory: "./merged",
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    rinkeby: {
      provider: () =>
        new HDWalletProvider(
          process.env.MNEMONIC,
          `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`
        ),
        network_id: 4,       // Rinkeby's id
        gas: 5500000,        // Rinkeby has a lower block limit than mainnet
        confirmations: 2,    // # of confs to wait between deployments. (default: 0)
        timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
        skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    test: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  compilers: {
    solc: {
      version: "0.5.16"
    }
  },
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  }
};
