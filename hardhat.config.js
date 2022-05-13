require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    Huygens_dev: {
      url: "http://18.182.45.18:8765",
      accounts: [
        "6E29154FAF61CFFE560850387AA9CF9B3370FCB16609E7BD09E85BEE74CCBE68"
      ]
    },
    Huygens: {
      url: "http://13.212.177.203:8765",
      accounts: [
        "6E29154FAF61CFFE560850387AA9CF9B3370FCB16609E7BD09E85BEE74CCBE68"
      ]
    },
  },
};
