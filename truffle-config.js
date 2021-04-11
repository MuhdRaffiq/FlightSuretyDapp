var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "original arrive spring doctor juice impose trumpet middle gaze stool blood ranch";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gas: 4600000
    }
  },
  compilers: {
    solc: {
      version: "^0.5.0"
    }
  }
};