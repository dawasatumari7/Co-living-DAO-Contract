# Co-living DAO Smart Contract

## Overview
Comprehensive decentralized autonomous organization smart contract for co-living spaces management. This feature introduces a complete governance and space management system with membership controls, proposal voting, treasury operations, and space booking functionality.

## Technical Implementation

### Key Features Added:
- **Membership Management**: Join/leave DAO with reputation tracking and membership fees
- **Proposal System**: Create, vote on, and execute proposals with weighted voting based on reputation
- **Space Management**: Create spaces, book accommodations, and manage occupancy
- **Treasury Operations**: Secure fund management with owner-controlled withdrawals
- **Governance**: Quorum-based decision making with 50% participation threshold

### Data Structures:
- `members` map: Tracks member status, reputation, join date, and space assignments
- `proposals` map: Stores proposal details, voting results, and execution status
- `spaces` map: Manages space information, capacity, fees, and availability
- `votes` map: Records individual voting decisions
- `space-occupants` map: Tracks space booking history

### Core Functions:
- `join-dao()`: Membership registration with 1 STX fee
- `create-proposal()`: Proposal creation with type categorization
- `vote-on-proposal()`: Weighted voting system based on reputation
- `create-space()`: Space registration with capacity and amenities
- `book-space()`: Space booking with payment processing
- `withdraw-from-treasury()`: Owner-controlled fund management

## Testing & Validation
- ✅ Contract passes clarinet check
- ✅ All npm tests successful 
- ✅ CI/CD pipeline configured
- ✅ Clarity v3 compliant with proper error handling
- ✅ Independent feature with no cross-contract dependencies
