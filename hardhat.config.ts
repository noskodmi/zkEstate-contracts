import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";

module.exports = {
  zksolc: {
    version: "1.3.10",
    compilerSource: "binary",
    settings: {},
  },
  defaultNetwork: "zkSyncTestnet",

  networks: {
    zkSyncTestnet: {
      url: "https://testnet.era.zksync.dev",
      ethNetwork: "https://goerli.infura.io/v3/723fae493ef5485381f4974be919da80", // RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
      zksync: true,
    },
  },
  solidity: {
    version: "0.8.8",
  },
};
