const HDWalletProvider = require("truffle-hdwallet-provider-privkey");
require('dotenv').config()
module.exports = {
  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  networks: {
    kovan: {
      provider: () => new HDWalletProvider([process.env.PRIVATE_KEY], `https://kovan.infura.io/v3/a4273886253a4c01b2e41cbfeb190ccd`),
      network_id: 42,       // Ropsten's id
    },
    rinkeby: {
      provider: () => new HDWalletProvider([process.env.PRIVATE_KEY], `https://rinkeby.infura.io/v3/a4273886253a4c01b2e41cbfeb190ccd`),
      network_id: 42,       // Ropsten's id
    },
    mainnet: {
      provider: () => new HDWalletProvider([process.env.PRIVATE_KEY], `https://mainnet.infura.io/v3/a4273886253a4c01b2e41cbfeb190ccd`),
      network_id: 42,       // Ropsten's id
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_KEY
  },
  compilers: {
    solc: {
      version: "0.6.12"
    }
  }
};
