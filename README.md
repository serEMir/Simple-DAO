# Simple DAO Project

This project implements a **Decentralized Autonomous Organization (DAO)** using Solidity. The DAO allows contributors to pool funds, create proposals, vote on them, and execute proposals if a quorum is met. It is designed to be deployed on Ethereum-compatible blockchains.

## Features

- **Contribution System**: Contributors can deposit ETH to gain shares in the DAO.
- **Proposal Creation**: Only the owner can create proposals for fund allocation.
- **Voting Mechanism**: Contributors can vote on proposals based on their shares.
- **Quorum Enforcement**: Proposals are executed only if the quorum is met.
- **Share Redemption**: Contributors can redeem their shares for ETH, if Contribution is still ongoing for that DAO cycle.

---

## Project Structure

### 1. **Contracts**
- **`src/DAO.sol`**: The main DAO contract that handles contributions, proposals, voting, and fund management.

### 2. **Scripts**
- **`script/DeployDAO.s.sol`**: A deployment script for deploying the DAO contract using Foundry.

### 3. **Tests**
- **`test/unit/DAOTest.t.sol`**: Unit tests for the DAO contract.
- **`test/integration/DAOInteractionsTest.t.sol`**: Integrations test to test the entire contract flow.

### 4. **Configuration**
- **`foundry.toml`**: Configuration file for Foundry, specifying paths and settings.
- **`.env`**: Environment variables for deployment (e.g., RPC URLs, API keys, **NO PRIVATE KEYS!!!**).

---

## Prerequisites

**Foundry**: Install Foundry by running:
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```

---

## Setup

**1. Clone the Repository:**
  ```bash
  git clone https://github.com/serEMir/simple-DAO.git
  cd simple-DAO
  ```

**2. Install Dependencies:**
  ```bash
  forge install
  ```

**3. Set Up Environment Variables: Create a `.env` file in the root directory and add the following:**
  ```bash
  SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
  ETHERSCAN_API_KEY=<your-etherscan-api-key>
  ACCOUNT=<your-key-store-account-name>
  ```
  - see **Deployment** for how to encrypt your private key in a key store

**4. Build the Project:**
  ```bash
  forge build
  ```

**5. Run Test:**
  ```bash
  forge test
  ```

---

## Deployment

To deploy the DAO contract to the Sepolia testnet:

- Ensure your `.env` file is correctly configured(rpc-url, API keys, keystore-accounts):
  - you can Encrypt a Private Key -> a keystore by:
    ```bash
    cast wallet import <your-account-name> --interactive
    ```
- Run the deployment script using the Makefile:
  ```bash
  make deploy-sepolia
  ```

---

## Contract Overview

**DAO Contract (`src/DAO.sol`)**

**Key Functions:**

- `initializeDAO(uint256 _contributionTimeEnd, uint256 _voteTime, uint256 _quorum)`: Initializes the DAO with contribution and voting parameters.
- `contribution()`: Allows contributors to deposit ETH and gain shares.
- `redeemShare(uint256 amount)`: Redeems shares for ETH.
- `createProposal(string description, uint256 amount, address recipient)`: Creates a proposal for fund allocation.
- `voteProposal(uint256 proposalId)`: Allows contributors to vote on a proposal.
- `executeProposal(uint256 proposalId)`: Executes a proposal if the quorum is met.

---

## License

This project is licensed under the MIT License.