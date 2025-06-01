require("@nomicfoundation/hardhat-toolbox");
require("./tasks/index")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    hell: {
      url: "http://127.0.0.1:8545",
      // accounts: [
      //   // Replace with the private key from Geth dev account
      //   "0xb71c71a67e1177ad4e901695e1b4b9ee17ae16c6668d313eac2f96dbcda3f291"
      // ]
    },
    docker: {
      url: "http://localhost:8545", // or the appropriate port
      accounts: [
        // Use one of the accounts from your dockerized node
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" // Ganache default key
      ]
    },
    hardhat: {
      forking: {
        url: "http://localhost:8545", // Geth node’s RPC
      }
    }    
  }
};
