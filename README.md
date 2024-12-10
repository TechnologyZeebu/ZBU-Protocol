# PSP-Invoice-Smart-Contract

## Prerequisites:
### Install Hardhat: 
If not already installed, you can add it to your project using npm:

```bash
Copy code
npm install --save-dev hardhat
```
### Project Setup: 
Ensure your Hardhat project is set up. If you haven't initialized a Hardhat project, you can do so by running:

```bash
Copy code
npx hardhat
```
Follow the prompts to create a sample project.

### Contract and Script Files: 
Place your Solidity contract in the contracts directory of your Hardhat project. The deployment script should be in the scripts directory.

## Sample Hardhat Deployment Script:
Here’s how you could write a deployment script for the Invoice contract. Save this script as deploy_invoice.js in the scripts directory.

javascript
Copy code
```// Import ethers from Hardhat package
const { ethers } = require("hardhat");

async function main() {
    // This is just a sample. Replace the arguments with those required by your contract constructor.
    const valueSigner = "0x..."; // address of the value signer
    const adminSigner = "0x..."; // address of the admin signer
    const usdRateContract = "0x..."; // address of the USD rate contract
    const stackerPool = "0x..."; // address of the stacker pool
    const earningPool = "0x..."; // address of the earning pool
    const burningPool = "0x..."; // address of the burning pool
    const systemPool = "0x..."; // address of the system pool
    const walletAddress = "0x..."; // address of the wallet contract
    const operationDelay = 3600; // operation delay in seconds
    const validateAddressFlag = true; // validation flag
    const withdrawSigners = ["0x...", "0x..."]; // array of withdraw signers addresses

    // Fetch the contract factory used to deploy contracts
    const Invoice = await ethers.getContractFactory("Invoice");
    
    // Deploy the contract
    const invoice = await Invoice.deploy(
        valueSigner,
        adminSigner,
        usdRateContract,
        stackerPool,
        earningPool,
        burningPool,
        systemPool,
        walletAddress,
        operationDelay,
        validateAddressFlag,
        withdrawSigners
    );

    // Wait for the contract to be deployed
    await invoice.deployed();

    // Print the address of the newly deployed contract
    console.log("Invoice deployed to:", invoice.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
```
## Running the Deployment Script:
After setting up your deployment script, you can deploy your contract by running:

bash
Copy code
npx hardhat run scripts/deploy_invoice.js --network <your-network-name>
Make sure to replace <your-network-name> with the name of the network you want to deploy to (e.g., mainnet, ropsten, rinkeby, etc.), which you should have defined in your Hardhat configuration file (hardhat.config.js).
