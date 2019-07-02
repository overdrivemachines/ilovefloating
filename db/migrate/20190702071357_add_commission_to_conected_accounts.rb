class AddCommissionToConectedAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :connected_accounts, :commission, :decimal, :precision => 5, :scale => 2
  end
end
