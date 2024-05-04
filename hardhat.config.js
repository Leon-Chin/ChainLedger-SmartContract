require("@matterlabs/hardhat-zksync-solc");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    defaultNetwork: "seplia",
    networks: {
      seplia: {
        url: "https://eth-sepolia.g.alchemy.com/v2/demo",
        accounts: [`0x${process.env.PRIVATE_KEY}`]
      },
    },
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
