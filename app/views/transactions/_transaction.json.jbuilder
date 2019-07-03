json.extract! transaction, :id, :name, :email, :phone, :start_date, :sales_rep_name, :item, :price, :connected_accounts_id, :charge_id, :created_at, :updated_at
json.url transaction_url(transaction, format: :json)
