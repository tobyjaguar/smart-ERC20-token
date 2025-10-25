# Smart Token

An ERC-20 token contract designed as a reward token for the "My Daily Trivia" Farcaster mini app. Users receive 1 SMART token per day for correctly answering trivia questions.

## Token Specifications

- **Name:** Smart
- **Symbol:** SMART
- **Decimals:** 0 (non-divisible whole tokens)
- **Initial Supply:** 1,000 tokens
- **Max Supply:** Unlimited (dynamic supply)
- **Network:** Base (Ethereum L2)

## Features

### Core Functionality
- ✅ ERC-20 compliant token
- ✅ Zero decimals - whole tokens only (1 SMART = 1, not 1e18)
- ✅ Dynamic supply with no maximum cap
- ✅ Minting and burning capabilities

### Admin Controls
- ✅ Multi-admin whitelist system
- ✅ Admins can add/remove other admins
- ✅ Only admins can mint new tokens
- ✅ Deployer is automatically the first admin

### Security Features
- ✅ Pausable transfers for emergency situations
- ✅ Burning capability for token holders and admins
- ✅ Access control for sensitive functions
- ✅ Built on battle-tested OpenZeppelin contracts

## Project Structure

```
smart-token/
├── src/
│   └── Smart.sol           # Main token contract
├── test/
│   └── Smart.t.sol         # Comprehensive test suite (37 tests)
├── script/
│   └── Deploy.s.sol        # Deployment script
├── foundry.toml            # Foundry configuration
└── README.md               # This file
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js (optional, for additional tooling)

## Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd smart-token
```

2. Install dependencies:
```bash
forge install
```

3. Build the contracts:
```bash
forge build
```

## Testing

Run the complete test suite (37 tests):
```bash
forge test
```

Run tests with detailed output:
```bash
forge test -vvv
```

Run tests with gas reporting:
```bash
forge test --gas-report
```

Run specific test:
```bash
forge test --match-test test_DailyRewardScenario
```

### Test Coverage

The test suite includes:
- Deployment and initialization tests
- Admin management (add/remove admins)
- Minting functionality and access control
- Burning capability
- Pause/unpause functionality
- Transfer restrictions when paused
- Integration tests
- Fuzz testing for critical functions
- Daily reward scenario simulation

## Deployment

### Environment Setup

Create a `.env` file in the project root:

```env
# Required for deployment
PRIVATE_KEY=your_private_key_here

# RPC URLs
BASE_RPC_URL=https://mainnet.base.org
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org

# For contract verification
BASESCAN_API_KEY=your_basescan_api_key_here
```

**Important:** Never commit your `.env` file! Add it to `.gitignore`.

### Deploy to Base Sepolia (Testnet)

```bash
source .env
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### Deploy to Base Mainnet

```bash
source .env
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify
```

### Dry Run (Simulation)

Test deployment without broadcasting:
```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $BASE_SEPOLIA_RPC_URL
```

## Contract Interaction

### Admin Functions

#### Add Admin
```solidity
function addAdmin(address account) external onlyAdmin
```
Adds a new admin to the contract.

**Example:**
```bash
cast send <CONTRACT_ADDRESS> "addAdmin(address)" <NEW_ADMIN_ADDRESS> \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Remove Admin
```solidity
function removeAdmin(address account) external onlyAdmin
```
Removes an admin from the contract.

#### Check Admin Status
```solidity
function isAdmin(address account) external view returns (bool)
```

**Example:**
```bash
cast call <CONTRACT_ADDRESS> "isAdmin(address)" <ADDRESS_TO_CHECK> \
  --rpc-url $BASE_RPC_URL
```

### Minting

```solidity
function mint(address to, uint256 amount) external onlyAdmin
```
Mints new tokens to a specified address. Only callable by admins.

**Example - Mint 1000 tokens to hot wallet:**
```bash
cast send <CONTRACT_ADDRESS> "mint(address,uint256)" <HOT_WALLET_ADDRESS> 1000 \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Pause/Unpause

```solidity
function pause() external onlyAdmin
function unpause() external onlyAdmin
function paused() external view returns (bool)
```

**Pause transfers:**
```bash
cast send <CONTRACT_ADDRESS> "pause()" \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Unpause transfers:**
```bash
cast send <CONTRACT_ADDRESS> "unpause()" \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Check pause status:**
```bash
cast call <CONTRACT_ADDRESS> "paused()" --rpc-url $BASE_RPC_URL
```

### Standard ERC-20 Functions

**Check balance:**
```bash
cast call <CONTRACT_ADDRESS> "balanceOf(address)" <ADDRESS> \
  --rpc-url $BASE_RPC_URL
```

**Transfer tokens:**
```bash
cast send <CONTRACT_ADDRESS> "transfer(address,uint256)" <TO_ADDRESS> <AMOUNT> \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Check total supply:**
```bash
cast call <CONTRACT_ADDRESS> "totalSupply()" --rpc-url $BASE_RPC_URL
```

**Burn tokens:**
```bash
cast send <CONTRACT_ADDRESS> "burn(uint256)" <AMOUNT> \
  --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY
```

## Use Case: My Daily Trivia

This token is designed specifically for the "My Daily Trivia" Farcaster mini app with the following workflow:

1. **Initial Setup:**
   - Deploy contract with initial supply
   - Mint tokens to hot wallet for distribution
   - Add backend service address as admin (if needed)

2. **Daily Operations:**
   - User answers trivia question correctly
   - Backend verifies answer
   - Backend sends 1 SMART token from hot wallet to user's address
   - User can only receive 1 token per day

3. **Supply Management:**
   - When hot wallet runs low, admin can mint more tokens
   - Incremental minting allows controlled token distribution
   - No need to transfer entire supply at once

4. **Emergency Situations:**
   - Admin can pause all transfers if issue detected
   - Investigate and resolve the issue
   - Unpause to resume normal operations

## Example Workflow

```javascript
// 1. Setup hot wallet (once)
// Mint initial tokens to hot wallet
await token.mint(hotWalletAddress, 10000);

// 2. Daily reward distribution
// When user answers correctly:
await token.transfer(userAddress, 1); // Send from hot wallet

// 3. Incremental supply management
// Check hot wallet balance periodically
const balance = await token.balanceOf(hotWalletAddress);
if (balance < 100) {
  // Mint more tokens to hot wallet
  await token.mint(hotWalletAddress, 5000);
}

// 4. Emergency pause (if needed)
await token.pause();
// ... investigate issue ...
await token.unpause();
```

## Security Considerations

1. **Private Key Management:**
   - Store private keys securely (never in code)
   - Use hardware wallets for mainnet deployments
   - Consider multi-sig for admin operations

2. **Admin Management:**
   - Add multiple trusted admins for redundancy
   - Regularly audit admin list
   - Use separate addresses for different roles

3. **Hot Wallet:**
   - Keep minimal balance in hot wallet
   - Monitor for unusual activity
   - Implement rate limiting on backend
   - Regular security audits

4. **Pause Functionality:**
   - Use only in genuine emergencies
   - Document pause/unpause events
   - Communicate with users when paused

## Gas Optimization

The contract uses:
- Custom errors instead of strings (saves gas)
- Efficient storage patterns
- OpenZeppelin's optimized implementations
- Solidity 0.8.27 with optimizer enabled

## Dependencies

- [OpenZeppelin Contracts v5.4.0](https://github.com/OpenZeppelin/openzeppelin-contracts)
  - ERC20.sol - Base token functionality
  - ERC20Burnable.sol - Burning capability
  - Ownable.sol - Ownership management
- [Forge Standard Library](https://github.com/foundry-rs/forge-std)

## Development

### Format Code
```bash
forge fmt
```

### Check Coverage
```bash
forge coverage
```

### Generate Gas Snapshot
```bash
forge snapshot
```

## License

MIT

## Support

For issues, questions, or contributions, please open an issue on the GitHub repository.

## Changelog

### v1.0.0 (Initial Release)
- ERC-20 token with 0 decimals
- Admin whitelist management
- Pausable transfers
- Minting and burning capabilities
- Comprehensive test suite
- Deployment scripts for Base network
