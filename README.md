# EsportsGrowth

## Overview

EsportsGrowth is a synthetic assets smart contract built on the Stacks blockchain that tracks competitive gaming and esports industry revenue. The contract enables users to mint synthetic tokens backed by STX collateral, with token prices dynamically adjusted based on real-world esports revenue data from multiple industry categories.

## Features

### Core Functionality
- **Synthetic Token Minting**: Create esports-backed synthetic tokens using STX as collateral
- **Dynamic Pricing**: Token prices automatically adjust based on weighted esports revenue data
- **Collateralized Positions**: Maintain over-collateralized positions with a minimum 150% collateral ratio
- **Oracle Integration**: Authorized oracles update real-world esports revenue data
- **Multi-Category Tracking**: Track revenue across four key esports sectors

### Esports Categories Tracked
1. **Competitive Gaming** (40% weight) - Professional esports tournaments and competitions
2. **Streaming Platforms** (30% weight) - Revenue from Twitch, YouTube Gaming, etc.
3. **Sponsorships** (20% weight) - Brand partnerships and sponsorship deals
4. **Merchandise** (10% weight) - Esports-related merchandise and products

### Security Features
- Over-collateralization requirements (150% minimum)
- Oracle authorization system
- Price staleness protection (24-hour maximum age)
- Position tracking and liquidation monitoring
- Owner-only administrative functions

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Token Standard**: Fungible Token (SIP-010 compatible foundation)
- **Precision**: 6 decimal places (1,000,000 = 1.0)
- **Collateral**: STX tokens
- **Oracle Update Frequency**: Maximum 24 hours between price updates

## Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) v16 or higher
- [Git](https://git-scm.com/)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd EsportsGrowth
   ```

2. **Navigate to contract directory**
   ```bash
   cd EsportsGrowth_contract
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Run tests**
   ```bash
   npm test
   ```

5. **Start development environment**
   ```bash
   clarinet console
   ```

## Usage Examples

### Contract Initialization
```clarity
;; Initialize the contract with default esports categories
(contract-call? .EsportsGrowth initialize)
```

### Minting Synthetic Tokens
```clarity
;; Mint 1000 synthetic tokens with 2000 STX collateral
(contract-call? .EsportsGrowth mint-synthetic u1000000 u2000000000)
```

### Burning Tokens and Redeeming Collateral
```clarity
;; Burn 500 synthetic tokens and redeem proportional collateral
(contract-call? .EsportsGrowth burn-synthetic u500000)
```

### Updating Revenue Data (Oracle Only)
```clarity
;; Update competitive gaming revenue to $100M (oracle function)
(contract-call? .EsportsGrowth update-revenue "competitive-gaming" u100000000)
```

### Checking Token Price
```clarity
;; Get current synthetic token price
(contract-call? .EsportsGrowth get-synthetic-price)
```

### Viewing Positions
```clarity
;; Check collateral position for an account
(contract-call? .EsportsGrowth get-collateral-position 'SP1234567890ABCDEF...)

;; Check synthetic token position
(contract-call? .EsportsGrowth get-synthetic-position 'SP1234567890ABCDEF...)

;; Check collateral ratio
(contract-call? .EsportsGrowth get-collateral-ratio 'SP1234567890ABCDEF...)
```

## Contract Functions Documentation

### Public Functions

#### Administrative Functions
- `initialize()` - Initialize contract with default esports categories (owner only)
- `add-oracle(oracle: principal)` - Add authorized oracle (owner only)
- `remove-oracle(oracle: principal)` - Remove oracle authorization (owner only)

#### Core Trading Functions
- `mint-synthetic(amount: uint, stx-collateral: uint)` - Mint synthetic tokens with STX collateral
- `burn-synthetic(amount: uint)` - Burn synthetic tokens and redeem collateral
- `transfer(amount: uint, sender: principal, recipient: principal, memo: optional buff)` - Transfer synthetic tokens

#### Oracle Functions
- `update-revenue(category: string-ascii, new-revenue: uint)` - Update esports revenue data (authorized oracles only)
- `calculate-synthetic-price()` - Recalculate synthetic token price based on revenue data

### Read-Only Functions

#### Balance and Supply Information
- `get-balance(account: principal)` - Get synthetic token balance
- `get-total-supply()` - Get total supply of synthetic tokens
- `get-synthetic-price()` - Get current synthetic token price

#### Position Information
- `get-collateral-position(account: principal)` - Get STX collateral amount
- `get-synthetic-position(account: principal)` - Get synthetic token position
- `get-collateral-ratio(account: principal)` - Calculate collateral ratio for position

#### Revenue and Market Data
- `get-category-revenue(category: string-ascii)` - Get revenue data for specific category
- `get-total-esports-revenue()` - Get weighted total esports revenue
- `is-price-stale()` - Check if price data needs updating

#### System Information
- `is-authorized-oracle(oracle: principal)` - Check oracle authorization status
- `get-contract-info()` - Get comprehensive contract metadata

## Deployment Guide

### Testnet Deployment

1. **Configure Clarinet**
   ```bash
   # Edit settings/Testnet.toml with your testnet configuration
   clarinet deployments generate --testnet
   ```

2. **Deploy to Testnet**
   ```bash
   clarinet deployments apply --testnet
   ```

### Mainnet Deployment

1. **Final Testing**
   ```bash
   npm run test:report
   ```

2. **Configure Mainnet Settings**
   ```bash
   # Edit settings/Mainnet.toml with production configuration
   clarinet deployments generate --mainnet
   ```

3. **Deploy to Mainnet**
   ```bash
   clarinet deployments apply --mainnet
   ```

### Post-Deployment Steps

1. **Initialize Contract**
   ```clarity
   (contract-call? .EsportsGrowth initialize)
   ```

2. **Set Up Oracles**
   ```clarity
   (contract-call? .EsportsGrowth add-oracle 'SP...oracle-address...)
   ```

3. **Initial Revenue Data**
   ```clarity
   ;; Update initial revenue data for all categories
   (contract-call? .EsportsGrowth update-revenue "competitive-gaming" u50000000)
   (contract-call? .EsportsGrowth update-revenue "streaming-platforms" u30000000)
   (contract-call? .EsportsGrowth update-revenue "sponsorships" u20000000)
   (contract-call? .EsportsGrowth update-revenue "merchandise" u10000000)
   ```

## Security Considerations

### Smart Contract Security
- **Over-collateralization**: 150% minimum collateral ratio prevents undercollateralized positions
- **Oracle Authorization**: Only authorized principals can update revenue data
- **Price Staleness**: Automatic detection of outdated price data
- **Owner Controls**: Critical functions restricted to contract owner

### Operational Security
- **Oracle Reliability**: Ensure oracle data sources are reliable and tamper-resistant
- **Collateral Monitoring**: Monitor collateral ratios to prevent liquidation risks
- **Price Validation**: Validate revenue data before oracle updates
- **Access Control**: Secure oracle private keys and owner credentials

### Risk Factors
- **Oracle Risk**: Dependency on external data sources for price updates
- **Collateral Risk**: STX price volatility affects collateral value
- **Liquidity Risk**: Limited synthetic token liquidity in early stages
- **Smart Contract Risk**: Potential bugs or vulnerabilities in contract logic

## Testing

### Running Tests
```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

### Test Coverage
The test suite covers:
- Contract initialization
- Token minting and burning
- Price calculation algorithms
- Oracle authorization and data updates
- Collateral ratio calculations
- Error handling and edge cases

## Development

### Project Structure
```
EsportsGrowth/
├── README.md
└── EsportsGrowth_contract/
    ├── contracts/
    │   └── EsportsGrowth.clar
    ├── tests/
    │   └── EsportsGrowth.test.ts
    ├── settings/
    │   ├── Devnet.toml
    │   ├── Testnet.toml
    │   └── Mainnet.toml
    ├── Clarinet.toml
    ├── package.json
    └── vitest.config.js
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request with detailed description

## License

This project is licensed under the ISC License.

## Support

For technical support or questions:
- Review the contract source code and tests
- Check existing issues in the repository
- Create detailed bug reports with reproduction steps

---

**Disclaimer**: This smart contract involves financial risks. Users should understand the mechanics of synthetic assets, collateralization requirements, and potential loss of funds before participating. Always conduct thorough due diligence and consider consulting with financial professionals.