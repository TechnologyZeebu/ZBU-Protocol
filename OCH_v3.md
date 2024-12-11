# **Zeebu Smart Contract-Based Clearing House Deployment Documentation**

---

## **Introduction**

The **Zeebu ecosystem** supports deploying smart contract-based clearing houses through **manual deployment by operators** or **automated deployment via Zeebu.fi**. These approaches cater to different levels of technical expertise, ensuring secure, transparent, and decentralized payment processing.

Nodes in the Zeebu ecosystem process transactions and settle invoices up to **$200,000** per transaction, enabling participants to actively contribute to a decentralized and transparent financial network.

---

## **What Does It Mean to "Deploy a Node"?**

Deploying a node involves deploying a **smart contract** on the blockchain that functions as an **On-Chain Clearing House (OCH)** for processing transactions. These smart contracts interact directly with the blockchain, allowing participants to validate and settle invoices while earning rewards.

---

## **Who Should Deploy a Node?**

**Anyone!**

Anyone meeting the selection criteria can deploy a node, contribute to the decentralized payment ecosystem, and earn rewards.

---

## **Why Deploy a Node?**

1. **Earn Passive Rewards**
    - **APY on Staked ZBU Tokens:** Generate passive income through staking.
    - **Invoice Transaction Rewards:** Earn **0.6% of the settled invoice amount** processed through the deployed node.
2. **Participate in the Zeebu Ecosystem**
    - **Decentralization:** Nodes operate on the blockchain, removing intermediaries and enabling secure operations.
    - **Transparency:** Every transaction is traceable and verifiable on the blockchain explorer.
3. **Ensure Transaction Settlement**
    - **On-Chain Clearing House (OCH):** Nodes automatically process invoices and execute tokenomics rules.

---

## **Participation Benefits**

1. **Decentralization:**
    - Contribute to decentralized payment processing and ensure secure, transparent transactions.
2. **Transparency:**
    - All transactions are on-chain and verifiable via blockchain explorers.
3. **Real-Time Rewards:**
    - Receive immediate rewards upon successful invoice transactions.

---

# **Deployment Approaches**

---

## **1. Manual Deployment by Operators**

**Description:**

Operators manually deploy the clearing house contract using their tools and infrastructure, offering maximum customization and control.

**Key Features:**

- **Multi-Signature Contracts:** Secure transaction approvals.
- **Operator Control:** Full responsibility for gas fees and dependencies.
- **Customization:** Advanced configurations and system integration.

---

## **Pre-requisites for Manual Deployment:**

1. **Wallet Configuration:**
    - Use a multi-signature wallet like **Gnosis Safe** or **Fireblocks.**
    - Add all required signatories with private key access.
2. **Gas Fees Management:**
    - Ensure sufficient native tokens (ETH, BNB) for gas fees.
    - Use tools like **Etherscan Gas Tracker** or **Blocknative.**
3. **Smart Contract Dependencies:**
    - Obtain the clearing house smart contract code from **Zeebu's repository.**
    - Use compatible tools like **Hardhat, Truffle,** or **Remix** for development.
4. **Development Environment:**
    - Install **Node.js** (v16+) and required libraries.
    - Connect to a blockchain node provider like **Infura** or **Alchemy.**
5. **Testing Framework:**
    - Use testnets (e.g., **Goerli, Sepolia**) for contract testing.
    - Set up tools like **Mocha** or **Chai.**

---

## **Manual Deployment Process:**

1. **Write a Deployment Script (deploy.js):**
    
    ```jsx
    javascript
    Copy code
    const { ethers } = require("hardhat");
    
    async function main() {
      const ClearingHouse = await ethers.getContractFactory("ClearingHouse");
      const clearingHouse = await ClearingHouse.deploy();
      console.log("ClearingHouse deployed to:", clearingHouse.address);
    }
    
    main().catch((error) => {
      console.error(error);
      process.exitCode = 1;
    });
    
    ```
    
2. **Deploy the Contract:**
    
    ```bash
    bash
    Copy code
    npx hardhat run scripts/deploy.js --network mainnet
    
    ```
    
3. **Verify Deployment:**
    - Use **Zeebu Explorer** or **Etherscan** to confirm deployment.

---

## **2. Automated Deployment via Zeebu.fi**

**Description:**

Zeebu.fi simplifies deployment by automating contract deployment through a **user-friendly interface.** This approach is ideal for participants who prefer a streamlined and efficient process without extensive technical knowledge.

---

### **Automated Deployment Process:**

---

### **Step 1: Registration on Zeebu.fi**

1. **Visit the Site:** Navigate to [Zeebu.fi](https://zeebu.fi/).
2. **Provide Reference Code:** Use your referral code during registration.
3. **Connect Crypto Wallet:** Use MetaMask or WalletConnect (MetaMask recommended for simplicity).
4. **Verify on Twitter:** Complete the required social media verification.
5. **Redirect to Home Page:** After successful registration, proceed to the main dashboard.

---

### **Step 2: Complete KYC/KYB (Know Your Customer/Business)**

1. **Click “Delegate” from the Top Menu.**
2. **Click “Become a Deployer”:** If KYC/KYB is incomplete, the system will redirect you to the KYC page.
3. **Complete KYC/KYB:** Choose either **Individual** or **Corporate Verification.**

---

### **Step 3: Become a Deployer**

1. **Click “Delegate” from the Top Menu.**
2. **View Active Nodes:** The system lists all active deployer nodes.
3. **Click “Become a Deployer.”**
4. **Select Node Type:**
    - **Super Node:** Requires deploying **five deployer nodes.**
    - **KOL Node:** Special category with founder recommendations.
    - **Normal Node:** Standard deployer node.
5. **Deploy the Node:**
    - Select the appropriate node type and click **“Deploy Node Now.”**
    - Confirm the deployment using your connected wallet provider.

---

### **Step 4: Activate the Node**

1. **Click “Activate Node.”**
2. **Complete the Three-Step Wizard:**
    - **Step 1:** Review and confirm the details.
    - **Step 2:** Execute pre-configured settings by clicking **“Execute Your Node.”**
    - **Step 3:** Submit the node for activation.

---

## **Selection Criteria for Node Activation:**

1. **Normal Node:** Must stake **200,000 ZBU** on the voting escrow contract.
2. **Super Node:** Must stake **10,000,000 ZBU** on the voting escrow contract.
3. **KOL Node:** Requires a **direct recommendation from the Zeebu founder.**

After submission, the node address is sent for **admin approval.**

---

# **Tools & Technologies**

### **Development Tools:**

- **Hardhat:** Smart contract development.
- **Truffle:** Testing and deployment framework.

### **Wallets:**

- **Gnosis Safe:** Multi-signature wallet.
- **MetaMask:** Wallet for managing gas fees.

### **API Providers:**

- **Infura:** Blockchain node provider.
- **Alchemy:** Blockchain development platform.

### **Explorers:**

- **Zeebu Explorer:** Verify contract deployments and monitor transactions.

---

By supporting both manual and automated deployment processes, Zeebu empowers clearing house operators with flexibility and control while ensuring seamless integration into the ecosystem.

For further assistance, contact **support@zeebu.com.** 🚀
