# VeloxCredit: Advanced Collateralized Lending Protocol

![Stacks](https://img.shields.io/badge/Stacks-Bitcoin%20Native-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

> Revolutionary DeFi infrastructure powering instant liquidity solutions through algorithmically-managed collateral positions with dynamic risk assessment.

## Overview

VeloxCredit is a sophisticated collateralized lending protocol built on the Stacks blockchain, leveraging Bitcoin's security for DeFi operations. The protocol enables users to deposit STX as collateral and borrow against it while maintaining over-collateralization requirements to ensure system stability.

### Key Features

- **🔒 Over-Collateralized Lending**: 150% minimum collateral ratio ensures system solvency
- **⚡ Dynamic Interest Rates**: Algorithmic 5% annual interest rate with per-block accrual
- **🛡️ Automated Liquidations**: 130% liquidation threshold with liquidator incentives
- **💰 Protocol Revenue**: 1% fee collection from interest payments
- **🔄 Flexible Repayments**: Support for both partial and full loan repayments
- **📊 Real-time Health Monitoring**: Continuous position health tracking

## System Architecture

### Core Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Depositors    │    │    Borrowers    │    │   Liquidators   │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │ Deposit STX          │ Create Loans         │ Liquidate
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    VeloxCredit Protocol                        │
├─────────────────────────────────────────────────────────────────┤
│  Collateral Management  │  Loan Engine  │  Interest Accrual   │
│  • Deposit Tracking     │  • Loan NFTs   │  • Per-block Calc   │
│  • Withdrawal Logic     │  • Health Check│  • Fee Collection   │
│  • Liquidation Pool     │  • Repayments  │  • Protocol Revenue │
└─────────────────────────────────────────────────────────────────┘
```

### Data Structures

#### Loan Structure

```clarity
{
  borrower: principal,
  collateral-amount: uint,
  loan-amount: uint,
  interest-accumulated: uint,
  creation-height: uint,
  last-interest-height: uint,
  status: (string-ascii 20)
}
```

#### User Management

- **User Deposits**: Track available collateral per user
- **User Loans**: Map users to their active loan IDs
- **Protocol Fees**: Height-based fee accumulation tracking

## Protocol Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Minimum Collateral Ratio | 150% | Required over-collateralization |
| Liquidation Threshold | 130% | Health ratio for liquidation eligibility |
| Annual Interest Rate | 5.0% | Yearly borrowing cost |
| Protocol Fee | 1.0% | Fee collected from interest payments |
| Liquidation Bonus | 5.0% | Incentive for liquidators |

## Contract Functions

### Core Operations

#### `deposit(amount: uint)`

Deposits STX as collateral into the protocol.

- Transfers STX from user to contract
- Updates user's collateral balance
- Increases total protocol collateral

#### `withdraw(amount: uint)`

Withdraws available collateral from the protocol.

- Validates sufficient unlocked collateral
- Transfers STX back to user
- Updates collateral tracking

#### `borrow(collateral-amount: uint, loan-amount: uint)`

Creates a new collateralized loan position.

- Validates collateral ratio requirements
- Locks specified collateral amount
- Issues loan proceeds to borrower
- Returns unique loan ID

#### `repay-loan(loan-id: uint, repay-amount: uint)`

Repays loan principal and accrued interest.

- Supports partial and full repayments
- Updates interest calculations
- Releases collateral on full repayment
- Handles loan closure logic

#### `liquidate(loan-id: uint)`

Liquidates undercollateralized loan positions.

- Verifies liquidation eligibility
- Transfers debt payment from liquidator
- Awards collateral and bonus to liquidator
- Collects protocol liquidation fees

### Administrative Functions

#### `set-paused(paused-state: bool)`

Emergency pause mechanism for protocol operations.

#### `withdraw-protocol-fees(amount: uint)`

Allows contract owner to withdraw accumulated protocol fees.

### Read-Only Functions

#### `get-loan-health(loan-id: uint)`

Returns comprehensive loan health metrics including collateral ratio and liquidation status.

#### `get-protocol-stats()`

Provides system-wide statistics including total collateral, borrowed amounts, and fee collection.

#### `is-liquidatable(loan-id: uint)`

Determines if a loan position is eligible for liquidation based on current health ratios.

## Data Flow

### Lending Process

```
1. User Deposits STX → Collateral Pool
2. User Creates Loan → Collateral Locked + Loan Issued
3. Interest Accrues → Per-block Calculation
4. User Repays → Principal + Interest + Collateral Released
```

### Liquidation Process

```
1. Loan Health Deteriorates → Below 130% Ratio
2. Liquidator Identifies → Undercollateralized Position
3. Liquidator Pays Debt → Full Outstanding Amount
4. Liquidator Receives → Collateral + 5% Bonus
5. Protocol Collects → Liquidation Fee
```

## Security Features

- **Over-collateralization**: 150% minimum ratio prevents undercollateralized lending
- **Real-time Health Monitoring**: Continuous position tracking for liquidation eligibility
- **Emergency Pause**: Administrative control for protocol security incidents
- **Atomic Operations**: All state changes occur within single transactions
- **Owner Controls**: Limited to fee withdrawal and emergency functions

## Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development toolkit
- Node.js 16+ for testing framework

### Setup

```bash
# Clone the repository
git clone https://github.com/rejoice-clinton/velox-credit.git
cd velox-credit

# Install dependencies
npm install

# Run contract checks
clarinet check

# Execute test suite
npm test
```

### Testing

The protocol includes comprehensive test coverage for:

- Deposit and withdrawal operations
- Loan creation and repayment flows
- Interest calculation accuracy
- Liquidation mechanism functionality
- Edge cases and error conditions

```bash
# Run specific test suites
npm run test:loans
npm run test:liquidation
npm run test:interest
```

## Risk Considerations

- **Liquidation Risk**: Borrowers must maintain >130% collateral ratio
- **Interest Accrual**: Debt increases per block, requiring active monitoring
- **Smart Contract Risk**: Protocol security depends on code correctness
- **Market Risk**: STX price volatility affects collateral values

## Roadmap

- [ ] Multi-asset collateral support
- [ ] Dynamic interest rate curves
- [ ] Governance token integration
- [ ] Cross-chain compatibility layer
- [ ] Advanced liquidation strategies
- [ ] Yield farming mechanisms

## Contributing

We welcome contributions to VeloxCredit! Please read our [Contributing Guidelines](CONTRIBUTING.md) and submit pull requests for review.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

VeloxCredit is experimental software. Use at your own risk. The protocol has not been audited and may contain bugs or vulnerabilities. Never invest more than you can afford to lose.

---

**Built with on Stacks blockchain for Bitcoin-native DeFi**
