# OCH contract

Invoice solidity contract is a sophisticated implementation designed to handle transactions and payments within a decentralized environment. It utilizes Ethereum's capabilities to secure transactions with digital signatures, manage fees, and distribute rewards using ERC-20 tokens.

## Contract Summary:

•	Name: Invoice<br> 
•	Base Contracts: Implements IERC20Receiver for token receipt and ReentrancyGuard for preventing re-entrant attacks.<br> 
•	Purpose: Manages payments and commissions between parties, ensuring secure and verifiable transactions.<br> 

## Key Components:

•	Interfaces<br> 
•	usdRate: Retrieves the exchange rate between Zeebu (ZBU) tokens and a USD pegged stablecoin (ZUSD).<br> 
•	walletContract: Provides a method to get a wallet's parent address, aiding in validations.<br> 

## Key Variables:

•	Multiple addresses for role-based access control, including owner, quoteSigner, adminSigner, and withdrawSigner.<br> 
•	Contract addresses for various functionalities like usdRateContract, walletAddress, and different pools (stackerPool, earningPool, burningPool).<br> 
•	Fee management through variables like merchantFee, customerFee, and burnRate.<br> 
•	Operation delays and nonce management for transaction ordering and replay protection.<br> 

## Critical Functions:

•	Configuration and Management: Functions to update contract addresses and parameters, ensuring dynamic configurability of the system.<br> 
•	Payment Processing: Includes validation and processing of payments, managing state changes through nonces, and updating balances.<br> 
•	Commission and Fee Handling: Methods to set and update fees and commissions dynamically, allowing for varied business logic.<br> 
•	Rewards Distribution: Functions to handle distribution of various types of rewards to different stakeholders based on predefined rules.<br> 

## Security Features:

•	Reentrancy Protection: Utilizes ReentrancyGuard to prevent re-entrant attacks.<br> 
•	Signature Validation: Employs signature checks to ensure that only authorized entities can execute significant functions.<br> 
•	Role-based Access Control: Ensures that sensitive actions can only be performed by designated signers and admins.<br> 

## Detailed Functionality:

•	Constructor: Initializes contract with essential parameters and roles.<br> 
•	Admin Functions: Includes admin-specific tasks like setting signer addresses and updating critical operational parameters.<br> 
•	Fee Configuration: Methods to configure fees for different transaction types.<br> 
•	Token Transfer and Reception: Handles the logic for secure token transfer based on the ERC-20 standard.<br> 
•	Validation Functions: Provides multiple checks for validating transaction integrity, user permissions, and operational prerequisites.<br> 


## Core Functionalities:

•	Payment Processing: The contract allows processing payments between customers and merchants, involving validation through signatures, ensuring transactions are legitimate and authorized.<br> 
•	Reward Management: Implements reward distribution logic where different types of rewards (merchant, customer, stacker, and earning rewards) are handled based on the transaction volume and pre-defined percentages.<br> 
•	Fee Management: Handles both merchant and customer fees, which can be dynamically adjusted.<br> 
•	Address and Signature Validation: Ensures that all critical operations are executed by valid addresses and are backed by correct signatures to prevent unauthorized actions.<br> 
•	Rate Conversion: Integrates with a USD rate contract to fetch the current rate for conversions during transactions, ensuring values are accurate and up-to-date.<br> 
•	Withdrawal Operations: Facilitates the withdrawal of tokens from the contract with multi-signature validation, adding an additional layer of security.<br> 
