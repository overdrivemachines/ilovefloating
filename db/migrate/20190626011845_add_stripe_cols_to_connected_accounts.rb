class AddStripeColsToConnectedAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :connected_accounts, :publishable_key, :string
    add_column :connected_accounts, :refresh_token, :string
    add_column :connected_accounts, :access_token, :string
    add_column :connected_accounts, :city, :string
    add_column :connected_accounts, :state, :string
    add_column :connected_accounts, :postal_code, :string
    add_column :connected_accounts, :url, :string
    add_column :connected_accounts, :dashboard_display_name, :string
  end
end
