class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :currency, null: false, default: 'USD'
      t.string :transaction_type, null: false
      t.references :source_wallet, null: true, foreign_key: { to_table: :wallets }
      t.references :target_wallet, null: true, foreign_key: { to_table: :wallets }
      t.text :description

      t.timestamps
    end

    add_index :transactions, :transaction_type
    add_index :transactions, :currency
    add_index :transactions, [ :source_wallet_id, :created_at ]
    add_index :transactions, [ :target_wallet_id, :created_at ]
  end
end
