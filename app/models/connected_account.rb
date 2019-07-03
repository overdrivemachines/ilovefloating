# == Schema Information
#
# Table name: connected_accounts
#
#  id                     :integer          not null, primary key
#  sid                    :string
#  name                   :string
#  status                 :string
#  balance                :decimal(8, 2)
#  connected              :date
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  publishable_key        :string
#  refresh_token          :string
#  access_token           :string
#  city                   :string
#  state                  :string
#  postal_code            :string
#  url                    :string
#  dashboard_display_name :string
#  commission             :decimal(5, 2)
#

class ConnectedAccount < ApplicationRecord
  has_many :transactions
  validates :sid, presence: true
end
