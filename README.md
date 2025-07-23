# 🏠 Co-living DAO Contract

> Decentralized governance for modern co-living spaces on Stacks blockchain

## 🌟 Overview

The Co-living DAO Contract brings democratic decision-making and automated expense management to shared living spaces. Transform your co-living arrangement into a structured, fair, and transparent community using blockchain technology.

## ✨ Key Features

### 🤝 Member Management
- **Join House**: Members join with a security deposit
- **Leave House**: Safe exit with deposit refund
- **Active Status**: Track active vs inactive members

### 🗳️ Democratic Voting System  
- **Create Proposals**: Submit ideas for house decisions
- **Vote on Issues**: Democratic voting with time limits
- **Execute Decisions**: Implement approved proposals automatically

### 💰 Smart Bill Splitting
- **Create Bills**: Add monthly expenses and utilities
- **Auto-Split**: Automatically divide costs among active members
- **Track Payments**: Monitor who has paid their share
- **House Balance**: Maintain shared funds for expenses

### 📋 House Rules & Governance
- **Add Rules**: Create and maintain house policies
- **Proposal Types**: Handle expenses, rules, and general decisions
- **Dispute Resolution**: Democratic voting for conflict resolution

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- Stacks wallet with STX tokens

### Installation
```bash
git clone <your-repo>
cd Co-living-DAO-Contract
clarinet check
```

## 📖 Usage Guide

### 1️⃣ Initialize the House
```clarity
(contract-call? .Co-living-DAO-Contract initialize-house u5000000) ;; 5 STX monthly rent
```

### 2️⃣ Join as a Member
```clarity
(contract-call? .Co-living-DAO-Contract join-house u1000000) ;; 1 STX deposit
```

### 3️⃣ Create Proposals
```clarity
(contract-call? .Co-living-DAO-Contract create-proposal 
    u"WiFi Upgrade" 
    u"Upgrade to faster internet plan" 
    "expense" 
    u500000) ;; 0.5 STX cost
```

### 4️⃣ Vote on Proposals
```clarity
(contract-call? .Co-living-DAO-Contract vote-on-proposal u1 true) ;; Vote yes on proposal #1
```

### 5️⃣ Create and Pay Bills
```clarity
;; Create a utility bill
(contract-call? .Co-living-DAO-Contract create-bill u"Electricity Bill" u2000000 u1440) ;; 2 STX, due in 10 days

;; Pay your share
(contract-call? .Co-living-DAO-Contract pay-bill u1)
```

### 6️⃣ Add House Rules
```clarity
(contract-call? .Co-living-DAO-Contract add-house-rule "quiet-hours" u"No loud music after 10 PM")
```

## 🔍 Read-Only Functions

### Check Member Status
```clarity
(contract-call? .Co-living-DAO-Contract get-member-info 'SP1234...ABCD)
(contract-call? .Co-living-DAO-Contract is-member 'SP1234...ABCD)
```

### View Proposals & Bills
```clarity
(contract-call? .Co-living-DAO-Contract get-proposal u1)
(contract-call? .Co-living-DAO-Contract get-bill u1)
(contract-call? .Co-living-DAO-Contract get-house-balance)
```

### Check House Rules
```clarity
(contract-call? .Co-living-DAO-Contract get-house-rule "quiet-hours")
```

## 💡 How It Works

### 🏗️ Architecture
- **Members**: Active participants with voting rights and payment obligations
- **Proposals**: Democratic decision-making mechanism with time-limited voting
- **Bills**: Automated expense splitting with payment tracking
- **House Balance**: Shared treasury for approved expenses

### ⚡ Smart Features
- **Automatic Bill Splitting**: Divides expenses equally among active members
- **Time-Limited Voting**: 144 blocks (~24 hours) voting window
- **Deposit System**: Security deposits ensure commitment
- **Democratic Execution**: Only majority-approved proposals execute

## 🔒 Security Features

- ✅ Member authentication for all actions
- ✅ Double-spending prevention for bills
- ✅ Proposal execution validation
- ✅ Balance checks before transfers
- ✅ Time-based voting restrictions

## 🛠️ Development

### Running Tests
```bash
npm install
npm test
```

### Contract Validation
```bash
clarinet check
```

## 📊 Contract Stats

- **Lines of Code**: 280+ lines
- **Functions**: 15 public + 8 read-only + 2 private
- **Data Maps**: 6 storage maps
- **Error Codes**: 10 comprehensive error types

## 🤔 Use Cases

- 🏠 **Shared Apartments**: Manage rent, utilities, and house rules
- 🏢 **Co-working Spaces**: Democratic facility decisions and expense sharing  
- 🏕️ **Community Living**: Structured governance for intentional communities
- 🎓 **Student Housing**: Fair and transparent dorm management

## 🆘 Support

For questions or issues:
1. Check the contract functions above
2. Review error codes in the contract
3. Test functions with Clarinet console

---

*Built with ❤️ for the co-living community on Stacks blockchain*
