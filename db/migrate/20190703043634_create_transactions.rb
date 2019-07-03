class CreateTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transactions do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.date :start_date
      t.string :sales_rep_name
      t.string :item
      t.decimal :price, :precision => 6, :scale => 2
      t.references :connected_accounts, foreign_key: true
      t.string :charge_id

      t.timestamps
    end
  end
end