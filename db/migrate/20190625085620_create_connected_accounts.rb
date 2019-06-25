class CreateConnectedAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :connected_accounts do |t|
      t.string :sid
      t.string :name
      t.string :status
      t.decimal :balance, :precision => 8, :scale => 2
      t.date :connected
      t.timestamps
    end
  end
end
