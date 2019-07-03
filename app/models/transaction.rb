class Transaction < ApplicationRecord
  belongs_to :connected_accounts
  validates :name, :sales_rep_name, :item, length: { minimum: 2 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, length: { minimum: 10 }
  validates :start_date, :connected_accounts, :charge_id, presence: true
  validates :price, numericality: { greater_than: 0, less_than: 10000.00 }
end
