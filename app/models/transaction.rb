# == Schema Information
#
# Table name: transactions
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  phone                :string
#  start_date           :date
#  sales_rep_name       :string
#  item                 :string
#  price                :decimal(6, 2)
#  connected_account_id :integer
#  charge_id            :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

class Transaction < ApplicationRecord
  belongs_to :connected_account
  validates :name, :sales_rep_name, :item, length: { minimum: 2 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, length: { minimum: 10 }
  validates :start_date, :connected_account, presence: true
  validates :price, numericality: { greater_than: 0, less_than: 10000.00 }
end
