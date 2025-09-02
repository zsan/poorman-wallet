# Create sample users
puts "Creating sample users..."

user1 = User.create!(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'password123'
)

user2 = User.create!(
  username: 'jane_smith',
  email: 'jane@example.com',
  password: 'password123'
)

puts "Created users: #{User.count}"

# Create sample teams
puts "Creating sample teams..."

team1 = Team.create!(
  name: 'Development Team',
  description: 'Software development team'
)

team2 = Team.create!(
  name: 'Marketing Team',
  description: 'Marketing and sales team'
)

puts "Created teams: #{Team.count}"

# Create sample stocks
puts "Creating sample stocks..."

stocks_data = [
  { symbol: 'AAPL', name: 'Apple Inc.', current_price: 150.00 },
  { symbol: 'GOOGL', name: 'Alphabet Inc.', current_price: 2500.00 },
  { symbol: 'MSFT', name: 'Microsoft Corporation', current_price: 300.00 },
  { symbol: 'BBRI.JK', name: 'Bank Rakyat Indonesia', current_price: 4500.00 },
  { symbol: 'BBCA.JK', name: 'Bank Central Asia', current_price: 8200.00 }
]

stocks_data.each do |stock_data|
  Stock.create!(stock_data)
end

puts "Created stocks: #{Stock.count}"

# Add some initial transactions
puts "Creating sample transactions..."

# Credit some money to user wallets
Transaction.create_credit!(user1.wallet_for('USD'), 1000.0, 'USD', 'Initial deposit')
Transaction.create_credit!(user1.wallet_for('IDR'), 15000000.0, 'IDR', 'Initial deposit')
Transaction.create_credit!(user2.wallet_for('USD'), 500.0, 'USD', 'Initial deposit')

# Credit money to team wallets
Transaction.create_credit!(team1.wallet_for('USD'), 5000.0, 'USD', 'Team budget allocation')
Transaction.create_credit!(team2.wallet_for('USD'), 3000.0, 'USD', 'Marketing budget')

# Credit money to stock wallets (representing company treasury)
Transaction.create_credit!(Stock.find_by(symbol: 'AAPL').wallet_for('USD'), 10000.0, 'USD', 'Company treasury')
Transaction.create_credit!(Stock.find_by(symbol: 'BBRI.JK').wallet_for('IDR'), 50000000.0, 'IDR', 'Company treasury')

# Sync wallet balances after credits but before transfers
puts "Syncing wallet balances after credits..."
Wallet.all.each(&:sync_balance!)

# Create some transfer transactions
Transaction.create_transfer!(
  user1.wallet_for('USD'),
  user2.wallet_for('USD'),
  100.0,
  'USD',
  'Payment for services'
)

Transaction.create_transfer!(
  team1.wallet_for('USD'),
  user1.wallet_for('USD'),
  200.0,
  'USD',
  'Bonus payment'
)

# Final sync of all wallet balances
puts "Final sync of wallet balances..."
Wallet.all.each(&:sync_balance!)

puts "Created transactions: #{Transaction.count}"
puts "Total wallets: #{Wallet.count}"

puts "Seed data created successfully!"
puts "\nSample login credentials:"
puts "Username: john_doe, Password: password123"
puts "Username: jane_smith, Password: password123"
