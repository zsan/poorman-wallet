class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets do |t|
      t.decimal :balance, precision: 15, scale: 2, default: 0.0, null: false
      t.string :currency, null: false, default: 'USD'
      t.references :walletable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :wallets, [ :walletable_type, :walletable_id ]
    add_index :wallets, :currency
  end
end
