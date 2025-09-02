# Internal Wallet Transactional System

A simple demo wallet system built with Rails 8, featuring multi-currency support, ACID-compliant transactions, and a custom stock price library.

## Features

### Core Wallet System
- **Generic Wallet Architecture**: Every entity (User, Team, Stock) has its own wallet(s)
- **Multi-Currency Support**: USD, EUR, IDR, JPY, GBP
- **ACID Transactions**: All wallet operations use database transactions
- **Balance Calculation**: Balances calculated from transaction history, not stored directly
- **Transaction Types**:
  - **Credit**: Money coming into the system (source_wallet = nil)
  - **Debit**: Money leaving the system (target_wallet = nil)
  - **Transfer**: Money moving between wallets within the system

### Authentication System
- Simple Custom authentication without external gems (for demo purpose)
- Session management with secure password hashing (bcrypt)
- Login/logout functionality

### API Endpoints
All API endpoints require authentication header: `Authorization: Bearer demo-api-key` (for demo purpose)

#### Transaction Endpoints
- `POST /api/v1/transactions/credit` - Add money to a wallet
- `POST /api/v1/transactions/debit` - Remove money from a wallet
- `POST /api/v1/transactions/transfer` - Transfer money between wallets
- `GET /api/v1/transactions` - List all transactions

#### Wallet Endpoints
- `GET /api/v1/wallets` - List all wallets
- `GET /api/v1/wallets/:id` - Get wallet details
- `GET /api/v1/wallets/:id/balance` - Get wallet balance
- `GET /api/v1/wallets/:id/transactions` - Get wallet transactions

### LatestStockPrice Library
Note: I don’t fully understand the specification, but here we go.

Custom gem-style library in `lib/latest_stock_price/` with three main classes:
- `LatestStockPrice::Price` - Get single stock price
- `LatestStockPrice::Prices` - Get multiple stock prices
- `LatestStockPrice::PriceAll` - Get all available stock prices

## Technology Stack

- **Rails 8.0.2** - Web framework
- **SQLite3** - Database
- **Tailwind CSS** - Styling
- **bcrypt** - Password hashing
- **Custom Authentication** - No external auth gems

## Database Schema

### Core Tables
- `users` - User accounts with authentication
- `teams` - Team entities
- `stocks` - Stock entities with current prices
- `wallets` - Polymorphic wallets for any entity
- `transactions` - All wallet transactions with ACID compliance

### Key Relationships
- Polymorphic association: `wallets` belongs to `walletable` (User, Team, Stock)
- Transactions reference source and target wallets (nullable for credits/debits)

## Installation & Setup

1. **Clone and Setup**
   ```bash
   cd wallet_system
   bundle install
   rails db:migrate
   rails db:seed
   rails credentials:edit -e development # and add rapidapi_key
   ```

2. **Start Server**
   ```bash
   bin/dev
   ```

3. **Access Application**
   - Web Interface: http://localhost:3000
   - Login with: `john_doe` / `password123` or `jane_smith` / `password123`

## Credentials

```sh
# rails credentials:edit -e development
rapidapi_key: RAPID_API
```

## API Usage Examples

### Create Credit Transaction
```bash
curl -X POST http://localhost:3000/api/v1/transactions/credit \
  -H "Authorization: Bearer demo-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "wallet_id": 1,
    "wallet_type": "user",
    "amount": 100.0,
    "currency": "USD",
    "description": "Initial deposit"
  }'
```

### Create Transfer Transaction
```bash
curl -X POST http://localhost:3000/api/v1/transactions/transfer \
  -H "Authorization: Bearer demo-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "source_wallet_id": 1,
    "source_wallet_type": "user",
    "target_wallet_id": 2,
    "target_wallet_type": "team",
    "amount": 50.0,
    "currency": "USD",
    "description": "Payment to team"
  }'
```

### Get Transactions
```bash
curl -X GET http://localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer demo-api-key"
```

## Stock Price Library Usage

```ruby
# Get multiple stock prices
prices = LatestStockPrice::Prices.get([ "NIFTY 50", "BAJFINANCE" ], api_key)

```

## Architecture Highlights

### ACID Compliance
All wallet operations are wrapped in database transactions:
```ruby
ActiveRecord::Base.transaction do
  transaction = Transaction.create_transfer!(source_wallet, target_wallet, amount, currency, description)
  source_wallet.sync_balance!
  target_wallet.sync_balance!
end
```

### Balance Calculation
Balances are calculated from transaction history, ensuring accuracy:
```ruby
def calculated_balance
  credits = target_transactions.sum(:amount) || 0
  debits = source_transactions.sum(:amount) || 0
  credits - debits
end
```

### Validation Rules
- Credits: `source_wallet` must be nil, `target_wallet` required
- Debits: `target_wallet` must be nil, `source_wallet` required
- Transfers: Both `source_wallet` and `target_wallet` required
- Currency consistency between wallets and transactions
- Sufficient balance validation for debits and transfers

## Testing

Run the test suite:
```bash
rails test
```
